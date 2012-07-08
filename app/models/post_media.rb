require "limelight"

class PostMedia
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  include Limelight::Images
  include Limelight::Popularity

  field :title
  field :content
  field :description # if a link, the pulled description from the url
  field :posted_ids, :default => [] # ids of users that have posted this
  field :posts_count, :default => 0 # how many reposts
  field :pushed_users_count, :default => 0 # the number of users this post has been pushed to
  field :neo4j_id
  field :status, :default => 'active'

  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'

  belongs_to :user, :index => true
  has_many :posts

  validate :title_length, :unique_source

  attr_accessible :title, :source_name, :source_url, :source_video_id, :source_title, :source_content, :embed_html
  attr_accessor :source_name, :source_url, :source_video_id, :source_title, :source_content

  before_validation :set_source_snippet
  before_create :current_user_own
  after_create :neo4j_create, :action_log_create, :process_images
  #after_save :update_denorms
  before_destroy :disconnect

  def to_param
    id.to_s
  end

  def created_at
    id.generation_time
  end

  def name
    title
  end

  def set_source_snippet
    if (@source_name && !@source_name.blank?) && (@source_url && !@source_url.blank?)
      source = SourceSnippet.new
      source.name = @source_name
      source.url = @source_url
      #source.title = @source_title unless @source_title.blank?
      #source.content = @source_content unless @source_content.blank?
      source.video_id = @source_video_id unless @source_video_id.blank?

      topic = Topic.where(:slug => @source_name.parameterize).first
      unless topic
        topic = user.topics.create(:name => @source_name)
      end
      source.id = topic.id

      add_source(source)
    end
  end

  def add_source(source)
    unless sources.find(source.id)
      self.sources << source
    end
  end

  # if required, checks that the given post URL is valid
  def has_valid_url
    if sources.length == 0
      errors.add(:url, "Source is required")
    end
    if sources.length > 0 && (sources[0].url.length < 3 || sources[0].url.length > 200)
      errors.add(:url, "Source URL must be between 3 and 200 characters long")
    end
  end

  def title_length
    if title && title.length > 125
      errors.add(:title, "Title cannot be more than 125 characters long")
    end
  end

  def unique_source
    if sources.length > 0 && !sources.first.url.blank? && !persisted?
      if PostMedia.where('sources.url' => sources.first.url).first
        errors.add('Link', "Source has already been added to Limelight")
      end
    end
  end

  def primary_source
    sources.first
  end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'post_media', 'subtype' => self.class.name, 'created_at' => created_at.to_i, 'score' => score.to_i)
    Neo4j.neo.add_node_to_index('post_media', 'uuid', id.to_s, node)

    Resque.enqueue(Neo4jPostMediaCreate, id.to_s)

    node
  end

  def user_posted(user_id)
    unless posted_ids.include?(user_id)
      self.posted_ids << user_id
      self.posts_count += 1
      save
    end
  end

  def current_user_own
    grant_owner(user.id)
  end

  def action_log_create
    ActionPost.create(:action => 'create', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def action_log_delete
    ActionPost.create(:action => 'delete', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def disconnect
    # remove from neo4j
    node = Neo4j.neo.get_node_index('posts', 'uuid', id.to_s)
    Neo4j.neo.delete_node!(node)

    FeedTopicItem.post_destroy(self)
    FeedLikeItem.post_destroy(self)
    FeedContributeItem.post_destroy(self)
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
            "Post Type" => _type,
            "Media Reposts" => posts_count,
            "Post Created At" => created_at,
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :slug => { :definition => :to_param, :properties => :short, :versions => [ :v1 ] },
    :type => { :definition => :_type, :properties => :short, :versions => [ :v1 ] },
    :title => { :properties => :short, :versions => [ :v1 ] },
    :user_id => { :properties => :short, :versions => [ :v1 ] },
    :posts_count => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :video => { :definition => lambda { |instance| instance.json_video }, :properties => :short, :versions => [ :v1 ] },
    :video_autoplay => { :definition => lambda { |instance| instance.json_video(true) }, :properties => :short, :versions => [ :v1 ] },
    :images => { :definition => lambda { |instance| instance.json_images }, :properties => :short, :versions => [ :v1 ] },
    :primary_source => { :type => :reference, :definition => :primary_source, :properties => :short, :versions => [ :v1 ] }

  def json_video(autoplay=nil)
    unless _type != 'Video' || embed_html.blank?
      video_embed(sources[0], 680, 480, nil, nil, embed_html, autoplay)
    end
  end

  def json_images
    if images.length > 0 || !remote_image_url.blank?
      {
        :ratio => image_ratio,
        :w => image_width,
        :h => image_height,
        :original => image_url(nil, nil, nil, true),
        :fit => {
            :large => image_url(:fit, :large),
            :normal => image_url(:fit, :normal),
            :small => image_url(:fit, :small)
        },
        :square => {
            :large => image_url(:square, :large),
            :normal => image_url(:square, :normal),
            :small => image_url(:square, :small)
        }
      }
    end
  end

  ##########
  # END JSON
  ##########

end