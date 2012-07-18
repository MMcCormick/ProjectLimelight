require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  include Limelight::Images
  include ImageHelper

  include ModelUtilitiesHelper

  @type_of_id = "4eb82a1caaf9060120000081"
  @related_to_id = "4f0a51745b1dc3000500016f"
  @limelight_id = '4ec69d9fcddc7f9fe80000b8'
  @limelight_feedback_id = '4ecab6c1cddc7fd77f000106'
  @stop_words = %w(a about above after again against all am an and any are arent as at be because been before being
                  below between both but by cant cannot could couldnt did didnt do does doesnt doing dont down
                  during each few for from further had hadnt has hasnt have havent having he hed hell hes her here
                  heres hers herself him himself his how hows i id ill im ive if in into is isnt it its its itself
                  lets me more most mustnt my myself no nor not of off on once only or other ought our ours
                  ourselves out over own same shant she shed shell shes should shouldnt so some such than that thats
                  the their theirs them themselves then there theres these they theyd theyll theyre theyve this
                  those through to too under until up very was wasnt we wed well were weve were werent what whats
                  when whens where wheres which while who whos whom why whys with wont would wouldnt you youd youll
                  youre youve your yours yourself yourselves)
  class << self; attr_accessor :type_of_id, :related_to_id, :limelight_id, :limelight_feedback_id, :stop_words end

  field :name
  field :url_pretty
  field :slug_pretty
  field :slug
  field :summary
  field :short_name
  field :status, :default => 'active'
  field :slug_locked
  field :user_id
  field :followers_count, :default => 0
  field :primary_type
  field :primary_type_id
  field :is_topic_type, :default => false # is this topic a type for other topics?
  field :talking_ids, :default => []
  field :response_count, :default => 0
  field :influencers, :default => {}
  field :score, :default => 0.0
  field :fb_page_id
  field :dbpedia
  field :opencyc
  field :freebase_id
  field :freebase_guid
  field :freebase_mid
  field :freebase_url
  field :freebase_deleted # if we manually deleted freebase info from this topic, can only re-enable by assigning an mid and repopulating
  field :use_freebase_image, :default => false
  field :wikipedia
  field :website
  field :websites_extra, :default => []
  field :neo4j_id, :type => Integer
  field :is_category, :default => false
  field :category_ids, :default => []

  belongs_to :user, :index => true
  embeds_many :aliases, :as => :has_alias, :class_name => 'TopicAlias'

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 50 }
  validates :slug_pretty, :uniqueness => { :case_sensitive => false, :message => 'This pretty slug is already in use' }
  validates :slug, :uniqueness => { :case_sensitive => false, :message => 'This slug is already in use' }
  validates :freebase_guid, :uniqueness => { :case_sensitive => false, :allow_blank => true, :message => 'This freebase guid is already in use' }
  validates :freebase_id, :uniqueness => { :case_sensitive => false, :allow_blank => true, :message => 'This freebase id is already in use' }
  validates_each :name do |record, attr, value|
    if Topic.stop_words.include?(value)
      record.errors.add attr, "This topic name is not permitted."
    end
  end

  attr_accessible :name, :summary, :aliases, :short_name
  attr_accessor :skip_fetch_external

  before_create :init_alias
  after_create :neo4j_create, :add_to_soulmate, :fetch_external_data
  before_validation :titleize_name, :generate_slug, :on => :create
  before_validation :update_name_alias, :update_url
  after_update :update_denorms
  before_destroy :remove_from_soulmate, :disconnect

  index({ :slug => 1 })
  index({ :slug_pretty => 1 })
  index({ :score => -1 })
  index({ :response_count => -1 })
  index({ :primary_type_id => 1 })
  index({ :is_category => 1 })
  index({ :category_ids => 1 })
  index({ :fb_page_id => 1 })
  index({ :freebase_guid => 1 }, { :sparse => true })
  index({ :freebase_id => 1 }, { :sparse => true })
  index({ "aliases.slug" => 1, :primary_type_id => 1 })

  # Return the topic slug instead of its ID
  def to_param
    self.url_pretty
  end

  def created_at
    id.generation_time
  end

  def title
    name
  end

  def titleize_name
    self.name = name.titleize
  end

  def generate_slug
    possible = name.parameterize
    found = Topic.where(:slug => possible.parameterize).first
    if found && found.id != id
      count = 0
      while found && found.id != id
        count += 1
        possible = name.parameterize + '-' + count.to_s
        found = Topic.where(:slug => possible.parameterize).first
      end
    end
    self.url_pretty = possible.gsub('-', ' ').titleize.gsub(' ', '')
    self.slug_pretty = possible.parameterize.gsub('-', '')
    self.slug = possible.parameterize
  end

  def fetch_external_data
    Resque.enqueue(TopicFetchExternalData, id.to_s) unless skip_fetch_external
  end

  def freebase
    if freebase_guid && freebase_guid[0] != '#'
      self.freebase_guid = "#" + freebase_guid.split('.').last
      save
    end

    if freebase_id || freebase_guid || freebase_mid
      query = {}
      query[:type] = "/common/topic" unless is_topic_type || is_category
      query[:notable_for] = [] unless is_topic_type || is_category
      query[:id] = freebase_id ? freebase_id : nil
      query[:guid] = !freebase_id && freebase_guid ? freebase_guid : nil
      query[:mid] = !freebase_id && !freebase_guid && freebase_mid ? freebase_mid : nil
      result = Ken.session.mqlread(query)
      if result
        result2 = Ken::Topic.get(result['mid'])
        result.merge!(result2.data.as_json) if result2
      end
      result
    end
  end

  def delete_freebase
    self.freebase_id = nil
    self.freebase_mid = nil
    self.freebase_guid = nil
    self.freebase_url = nil
    self.freebase_deleted = true
    self.use_freebase_image = false
    self.websites_extra = []
  end

  def freebase_repopulate(overwrite_text=false, overwrite_aliases=false, overwrite_primary_type=false, overwrite_image=false)
    return if !freebase_mid && freebase_deleted

    # get or find the freebase object
    freebase_search = nil
    freebase_object = freebase

    unless freebase_object
      search = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&limit=3&query=#{URI::encode(name)}")
      return unless search && search['result'] && search['result'].first && ((search['result'].first['notable'] && search['result'].first['score'] >= 50) || search['result'].first['score'] >= 800)

      search['result'].each do |s|
        if s['name'].parameterize == name.parameterize && s['score'] >= 50
          freebase_search = s
          break
        end
      end
      # make sure the names match up at least a little bit
      unless !search || freebase_search
        return unless (search['result'].first['name'].parameterize.include?(name.parameterize) && search['result'].first['score'] > 100) || search['result'].first['score'] >= 1500
        freebase_search = search['result'].first
      end

      self.freebase_mid = freebase_search['mid']
      freebase_object = self.freebase
      return unless freebase_object
    end

    existing_topic = Topic.where(:freebase_guid => freebase_object['guid']).first
    return if existing_topic && existing_topic.id != id

    # basics
    self.freebase_id = freebase_object['id']
    self.freebase_guid = freebase_object['guid']
    self.freebase_mid = freebase_object['mid']
    self.freebase_url = freebase_object['url']
    self.summary = freebase_object['description'] unless summary

    # store extra websites
    if freebase_object['webpage']
      freebase_object['webpage'].each do |w|
        if w['text'] == '{name}'
          self.website = w['url']
        elsif ['wikipedia','new york times','crunchbase','imdb'].include?(w['text'].downcase) && !websites_extra.detect{|we| we['name'] == w['text']}
          self.websites_extra << {
                  'name' => w['text'],
                  'url' => w['url']
          }
        end
      end
    end

    # try to connect primary type
    type_connection = TopicConnection.find(Topic.type_of_id)
    if freebase_object['notable_for'] && freebase_object['notable_for'].length > 0 && (overwrite_primary_type || !primary_type_id)
      type_topic = Topic.where(:freebase_id => freebase_object['notable_for'][0]).first

      # if we didn't find the type topic, fetch it from freebase and check the name
      freebase_type_topic = nil
      unless type_topic
        freebase_type_topic = Ken.session.mqlread({ :id => freebase_object['notable_for'][0], :mid => nil, :name => nil })
        if freebase_type_topic
          type_topic = Topic.where("aliases.slug" => freebase_type_topic['name'].parameterize).first
        end
      end

      if type_topic || freebase_type_topic
        new_type = false
        if freebase_type_topic && !type_topic
          type_topic = Topic.new
          type_topic.user_id = User.marc_id
          type_topic.skip_fetch_external = true
          new_type = true
        end

        if freebase_type_topic
          extra = Ken::Topic.get(freebase_type_topic['mid'])
          freebase_type_topic.merge!(extra.data.as_json) if extra
          type_topic.freebase_mid = freebase_type_topic['mid']
          type_topic.freebase_id = freebase_type_topic['id']
          type_topic.freebase_guid = freebase_type_topic['guid']
          type_topic.freebase_url = freebase_type_topic['url']
          type_topic.name = freebase_type_topic['text'] ? freebase_type_topic['text'] : freebase_type_topic['name']
          type_topic.summary = freebase_type_topic['description'] unless type_topic.summary
          new_type = true
        end

        if type_topic.name && !type_topic.name.blank?
          saved = new_type ? type_topic.save : false
          if saved || !new_type

            if primary_type_id
              old_type_topic = Topic.find(primary_type_id)
              TopicConnection.remove(type_connection, self, old_type_topic) if old_type_topic
            end

            set_primary_type(type_topic.name, type_topic.id)
            TopicConnection.add(type_connection, self, type_topic, User.marc_id, {:pull => false, :reverse_pull => true})
          end
        end
      end
    end

    # update the image
    if images.length == 0 || overwrite_image
      self.active_image_version = 0
      self.use_freebase_image = true
    end

    # overwrite certain things
    self.name = (freebase_object['name'] ? freebase_object['name'] : freebase_object['text']) if !name || overwrite_text
    self.summary = freebase_object['description']  if !summary || overwrite_text

    if overwrite_aliases && freebase_object['aliases'] && freebase_object['aliases'].length > 0
      update_aliases(freebase_object['aliases'])
    end

    save
  end

  #
  # Aliases
  #

  def init_alias
    self.aliases ||= []
    add_alias(name, false, true)
  end

  def get_alias(new_alias)
    self.aliases.where(:slug => new_alias.parameterize).first
  end

  def add_alias(new_alias, ooac=false, hidden=false)
    return unless new_alias && !new_alias.blank?

    unless get_alias(new_alias)
      self.aliases << TopicAlias.new(:name => new_alias, :slug => new_alias.parameterize, :hash => new_alias.parameterize.gsub('-', ''), :ooac => ooac, :hidden => hidden)
      Resque.enqueue(SmCreateTopic, id.to_s)
      true
    end
  end

  def remove_alias old_alias
    return unless old_alias && !old_alias.blank?
    self.aliases.where(:name => old_alias).delete
    Resque.enqueue(SmCreateTopic, id.to_s)
  end

  def update_alias(alias_id, name, ooac, hidden=false)
    found = self.aliases.find(alias_id)
    if found
      if ooac == true
        existing = Topic.where('aliases.slug' => name.parameterize).to_a
        if existing.length > 1
          names = []
          existing.each {|t| names << t.name if t.id != id}
          names = names.join(', ')
          return "The '#{names}' topic already have an alias with this name."
        end
      end
      found.name = name unless name.blank?
      found.slug = name.parameterize unless name.blank?
      found.ooac = ooac
      found.hidden = hidden
      Resque.enqueue(SmCreateTopic, id.to_s)
    end
    true
  end

  def update_aliases new_aliases
    self.aliases = []
    init_alias

    new_aliases = new_aliases.split(', ') unless new_aliases.is_a? Array
    new_aliases.each do |new_alias|
      add_alias(new_alias)
    end
  end

  def update_name_alias
    #if short_name_changed?
    #  update_aliases(also_known_as)
    #  remove_alias(short_name_was)
    #  add_alias(short_name)
    #end
    if name_changed?
      if name_was
        remove_alias(name_was.pluralize)
        remove_alias(name_was.singularize)
      end
      add_alias(name.pluralize, false, true)
      add_alias(name.singularize, false, true)
    end
  end

  def update_url
    if url_pretty_changed?
      self.slug_pretty = url_pretty.parameterize.gsub('-', '')
    end
  end

  def has_alias? name
    aliases.detect {|data| data.slug == name.parameterize}
  end

  def also_known_as
    also_known_as = Array.new
    aliases.each do |also|
      if also.slug != name.parameterize && also.slug != name.pluralize.parameterize && also.slug != name.singularize.parameterize && also.slug != short_name
        also_known_as << also.name
      end
    end
    also_known_as
  end

  #
  # SoulMate
  #

  def add_to_soulmate
    Resque.enqueue(SmCreateTopic, id.to_s)
  end

  def remove_from_soulmate
    Resque.enqueue(SmDestroyTopic, id.to_s)
  end

  #
  # Primary Type
  #

  def set_primary_type(primary_name, primary_id)
    topic = Topic.find(primary_id)
    if topic
      self.primary_type = topic.name
      self.primary_type_id = topic.id
      topic.is_topic_type = true
      topic.save
      Resque.enqueue(SmCreateTopic, id.to_s)
    end
  end

  def unset_primary_type
    self.primary_type = nil
    self.primary_type_id = nil
    Resque.enqueue(SmCreateTopic, id.to_s)
  end

  #
  # Merge
  # aliased_topic is the old topic (the topic being merged in)
  #

  def merge(aliased_topic)
    self.aliases = aliases | aliased_topic.aliases

    # Unfollowing (must happen before mention updates bc root_id may change for talks about the aliased old topic)
    followers = User.where(:following_topics => { "$in" => [id, aliased_topic.id] }).to_a
    followers.each do |follower|
      follower.unfollow_topic aliased_topic
      follower.unfollow_topic self
      follower.save
    end

    # Update topic mentions
    objects = Post.where("topic_mentions._id" => aliased_topic.id)
    objects.each do |object|
      # if an object mentions both, delete the old one
      if object.mentions_topic?(aliased_topic.id) && object.mentions_topic?(id)
        object.topic_mentions.destroy_all(conditions: { id: aliased_topic.id })
      end
      object.root_id = id if object.root_id == aliased_topic.id
      object.content = object.content.gsub(aliased_topic.id.to_s, id.to_s) if object.content
      object.title = object.title.gsub(aliased_topic.id.to_s, id.to_s) if object.title
      object.save!
    end

    topic_mention_updates = {}
    topic_mention_updates["topic_mentions.$.name"] = name
    topic_mention_updates["topic_mentions.$.slug"] = slug
    topic_mention_updates["topic_mentions.$._id"] = id
    Post.where("topic_mentions._id" => aliased_topic.id).update_all(topic_mention_updates)

    # NEO4J: Move Connections
    rels = Neo4j.get_topic_relationships aliased_topic.id
    rels.each do |rel|
      rev = (rel[0] == rel[1]['reverse_name'])
      rel[1]['connections'].each do |snip|
        unless Neo4j.get_connection(rel[1]['connection_id'], (rev ? snip['uuid'] : id), (rev ? id : snip['uuid']))
          connection = TopicConnection.find(rel[1]['connection_id'])
          con_topic = Topic.find(snip['uuid'])
          TopicConnection.add(connection, (rev ? con_topic : self), (rev ? self : con_topic), snip['user_id'],
                              {:pull => snip['pull'], :reverse_pull => snip['reverse_pull']})
        end
      end
    end

    # Update primary_type_id's on other topics
    Topic.where(:primary_type_id => aliased_topic.id).update_all(:primary_type_id => id, :primary_type => name)

    # Following
    followers.each do |follower|
      follower.follow_topic self
      follower.save
    end

    Resque.enqueue(SmCreateTopic, id.to_s)
    Resque.enqueue(SmDestroyTopic, aliased_topic.id.to_s)
  end

  def raw_image(w,h,m)
    default_image_url(self, w, h, m, true)
  end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'topic', 'name' => name, 'created_at' => created_at.to_i, 'score' => score.to_i)
    Neo4j.neo.add_node_to_index('topics', 'uuid', id.to_s, node)
    self.neo4j_id = Neo4j.parse_id(node['self'])
    save
    node
  end

  def neo4j_update
    node = Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
    Neo4j.neo.set_node_properties(node, {'name' => name, 'score' => score.to_i})
  end

  def neo4j_node
    Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
  end

  def disconnect
    # remove mentions of this topic (also removes from user feeds)
    Post.where("topic_mention_ids" => id).each do |object|
      object.remove_topic_mention(self)
      object.save
    end

    # remove from neo4j
    node = Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
    Neo4j.neo.delete_node!(node)

    # reset primary types
    Topic.where('primary_type_id' => id).each do |topic|
      topic.unset_primary_type
      topic.save
    end

    # update those users following this topic
    User.collection.find({ :following_topics => id }).
            update_all({
                  "$inc" => {
                    :following_topics_count => -1,
                  },
                  "$pull" => {
                    :following_topics => id
                  }
            })

    # remove from popularity actions
    actions = PopularityAction.where("pop_snippets._id" => id)
    actions.each do |a|
      a.pop_snippets.find(id).delete
      a.save
    end
  end

  def user_influence(id)
    influencers[id.to_s]["influence"] if influencers[id.to_s]
  end

  def user_percentile(id)
    influencers[id.to_s]["percentile"] if influencers[id.to_s]
  end

  # only returns visible aliases
  def visible_aliases
    aliases.select { |a| !a[:hidden] }
  end

  def short_summary
    if summary
      short = summary.split('.')[0,1].join('. ') + '.'
      #if short.length < 500
      #  short += summary.split('.')[1,2].join('. ') + '.'
      #end
      #short
    end
  end

  def all_websites
    response = []
    response << { :name => 'Official', :url => website } if website
    response << { :name => 'Freebase', :url => freebase_url } if freebase_url
    websites_extra.each do |w|
      response << { :name => w[:name], :url => w[:url] }
    end
    response
  end

  def add_category(id)
    unless category_ids.include?(id)
      self.category_ids << id
    end
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
            "Topic Name" => name,
            "Topic Score" => score,
            "Topic Response Count" => response_count,
            "Topic Followers" => followers_count,
            "Topic Created At" => created_at,
            "Topic Primary Type" => primary_type
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :slug => { :properties => :short, :versions => [ :v1 ] },
    :url_pretty => { :properties => :short, :versions => [ :v1 ] },
    :url => { :definition => lambda { |instance| "/#{instance.to_param}" }, :properties => :short, :versions => [ :v1 ] },
    :type => { :definition => lambda { |instance| 'Topic' }, :properties => :short, :versions => [ :v1 ] },
    :name => { :properties => :short, :versions => [ :v1 ] },
    :summary => { :definition => :short_summary, :properties => :short, :versions => [ :v1 ] },
    :score => { :properties => :short, :versions => [ :v1 ] },
    :followers_count => { :properties => :short, :versions => [ :v1 ] },
    :primary_type => { :properties => :short, :versions => [ :v1 ] },
    :primary_type_id => { :properties => :short, :versions => [ :v1 ] },
    :category_ids => { :properties => :short, :versions => [ :v1 ] },
    :images => { :definition => lambda { |instance| Topic.json_images(instance) }, :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :created_at_pretty => { :definition => lambda { |instance| instance.pretty_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :visible_alias_count => { :definition => lambda { |instance| instance.visible_aliases.length }, :properties => :public, :versions => [ :v1 ]},
    :aliases => { :type => :reference, :properties => :public, :versions => [ :v1 ] },
    :websites => { :definition => :all_websites, :properties => :public, :versions => [ :v1 ] },
    :freebase_url => { :properties => :public, :versions => [ :v1 ] }

  class << self

    def json_images(model)
      {
        :ratio => model.image_ratio,
        :w => model.image_width,
        :h => model.image_height,
        :original => model.image_url(nil, nil, nil, true),
        :fit => {
          :large => model.image_url(:fit, :large),
          :normal => model.image_url(:fit, :normal),
          :small => model.image_url(:fit, :small)
        },
        :square => {
          :large => model.image_url(:square, :large),
          :normal => model.image_url(:square, :normal),
          :small => model.image_url(:square, :small)
        }
      }
    end

    ##########
    # END JSON
    ##########

    # find a topic by slug or id
    def find_by_slug_id(id)
      if Moped::BSON::ObjectId.legal?(id)
        Topic.find(id)
      else
        Topic.where(:slug_pretty => id.parameterize).first
      end
    end

    # takes a hash of filters to narrow down a topic query
    def parse_filters(topics, filters)
      if filters[:sort]
        if filters[:sort][1] == 'desc'
          topics = topics.desc(filters[:sort][0])
        else
          topics = topics.asc(filters[:sort][0])
        end
      else
        topics = topics.asc(:slug)
      end

      if filters[:limit] && filters[:limit].to_i < 100
        topics = topics.limit(filters[:limit])
      else
        topics = topics.limit(100)
      end

      if filters[:page]
        topics = topics.skip(filters[:limit].to_i * (filters[:page].to_i-1))
      end

      if filters[:type]
        if filters[:type] == 'category'
          topics = topics.where(:is_category => true)
        end
      end

      topics
    end

    def top_by_category(limit)
      categories = Topic.where(:is_category => true).asc(:slug)
      topics = Topic.where(:category_ids => {"$in" => categories.map{|c| c.id}}).desc(:score).limit(100).to_a
      result = {}
      categories.each do |c|
        result[c.id.to_s] = {
                :category => c,
                :topics => []
        }
      end
      topics.each do |t|
        t.category_ids.each do |cid|
          result[cid.to_s][:topics] << t
        end
      end

      results = result.map {|k,v| v}
      results.delete_if {|r| r[:topics].empty?}
      results
    end

    # Checks if there is an untyped topic with an alias equal to the name. If so, returns that topic, if not, returns new topic
    def find_untyped_or_create(name, user)
      alias_topic = Topic.where("aliases.slug" => name.parameterize, "primary_type_id" => {"$exists" => false}).first
      if alias_topic
        alias_topic
      else
        user.topics.create({name: name})
      end
    end

    # find mentions in a body of text and return the topic matches
    # optionally return how often the mention occured in the text
    def parse_text(text, ooac=true, with_counts=nil, limit=nil)
      words = text.split(' ')
      word_combos = with_counts ? {} : []
      words.length.times do |i|
        5.times do |x|
          word = ''
          x.times do |y|
            word += words[i+y].tr('^A-Za-z0-9', '').downcase if words[i+y]
          end
          unless word.blank? || word.length <= 2
            if with_counts
              word_combos[word] ||= {:count => 0}
              word_combos[word][:count] += 1
            elsif !word_combos.include? word
              word_combos << word
            end
          end
          break unless words[i+x]
        end
      end

      if word_combos.length > 0
        hash_query = {'$in' => (with_counts ? word_combos.keys : word_combos)}
        if ooac == true
          hash_query['aliases.ooac'] = true
        end
        matches = Topic.where(:status => 'active').any_of({:short_name => {'$in' => (with_counts ? word_combos.keys : word_combos)}}, {'aliases.hash' => hash_query}).desc(:pm)
        matches = matches.limit(limit) if limit
      else
        matches = []
      end

      # Remove shorter versions of topics. For example - if 'limelight' and 'limelight feedback' were found, remove 'limelight' and keep the more specific topic.
      cleaned = []
      matches.each do |match|
        found = false

        matches.each do |match2|
          if match.id != match2.id && match2.name.downcase.strip.gsub(/[^\w ]/, '').include?(match.name.downcase.strip.gsub(/[^\w ]/, ''))
            found = true
            break
          end
        end

        unless found == true
          cleaned << match
        end
      end

      if with_counts
        processed_matches = {}
        cleaned.each do |match|
          count = 1
          word_combos.each do |name,v|
            if match.short_name == name || match.aliases.detect{|a| a.hash == name}
              count = v[:count]
              break
            end
          end
          processed_matches[match.id.to_s] = {
                  :topic => match,
                  :count => count
          }
        end
        cleaned = processed_matches
      end

      cleaned
    end

    # given text and topics, figure out which aliases are mentioned in the text
    def parse_aliases(text, topics)
      response = []
      aggregates = {}
      search_string = text.downcase.strip.gsub(/[^\w ]/, '')
      topics.each do |topic|
        slug = nil
        match = nil
        if search_string.index(topic.name.strip.gsub(/[^\w ]/, ''))
          slug = topic.name.strip.gsub(/[^\w ]/, '')
          match = topic.name
        else
          topic.aliases.each do |info|
            if search_string.index(info.name.downcase.strip.gsub(/[^\w ]/, ''))
              slug = info.name.downcase.strip.gsub(/[^\w ]/, '')
              match = info.name
              break
            end
          end
        end

        if slug && match
          aggregates[slug] ||= {:topics => []}
          aggregates[slug][:topics] << {:topic => topic, :match => match, :slug => slug}
        end
      end

      aggregates.each do |i,aggregate|
        response << aggregate
      end

      response
    end

    # clean and get all word combinations in a string
    def combinalities(string)
      return [] unless string && !string.blank?

      # generate the word combinations in the tweet (to find topics based on) and remove short words
      words = (string.split - Topic.stop_words).join(' ').gsub('-', ' ').downcase.gsub("'s", '').gsub(/[^a-z0-9 ]/, '').split.select { |w| w.length > 2 || w.match(/[0-9]/) }.join(' ')
      words = words.split(" ")
      #singular_words = words.map{|w| w.singularize}
      #words = singular_words
      combinaties = []
      i=0
      while i <= words.length-1
        combinaties << words[i].downcase
        unless i == words.length-1
          words[(i+1)..(words.length-1)].each{|volgend_element|
            combinaties<<(combinaties.last.dup<<" #{volgend_element}")
          }
        end
        i+=1
      end
      combinaties
    end

    # use alchemy api and limelight to produce topic suggestions for a given url
    def suggestions_by_url(url, title=nil, limit=5)
      suggestions = []

      if title
        combinations = Topic.combinalities(title)
        topics = Topic.where("aliases.slug" => {"$in" => combinations.map{|c| c.parameterize}}).desc(:response_count)
        topics.each do |t|
          suggestions << { :id => t.id.to_s, :name => t.name }
        end
      end

      postData = Net::HTTP.post_form(
              URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities"),
              {
                      :url => url,
                      :apikey => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
                      :outputMode => 'json',
                      #:sourceText => 'cleaned',
                      :maxRetrieve => 10
              }
      )

      entities = JSON.parse(postData.body)['entities']

      if entities
        entities.each do |e|
          if e['relevance'].to_f >= 0.60

            # try to find the topic in Limelight
            if e['disambiguated'] && (e['disambiguated']['freebase'] || e['relevance'].to_f >= 0.80)

              topic = false

              if e['disambiguated']['freebase']
                topic = Topic.where(:freebase_guid => e['disambiguated']['freebase'].split('.').last).first

                # didn't find the topic with the freebase guid, check names
                unless topic
                  topic = Topic.where("aliases.slug" => e['disambiguated']['name'].parameterize, :primary_type_id => {'$exists' => true}).desc(:response_count).first
                  topic.freebase_guid = e['disambiguated']['freebase'].split('.').last if topic
                end
              end

              if topic
                suggestions << { :id => topic.id.to_s, :name => topic.name }
              else
                suggestions << { :id => 0, :name => e['disambiguated']['name'] }
              end
            end
          end
        end
      end

      suggestions.uniq! {|s| s[:name] }
      suggestions[0..limit]
    end

  end

  protected

  #TODO: check that soulmate gets updated if this topic is a type for another topic
  def update_denorms
    soulmate = nil
    primary_type_updates = {}

    if name_changed?
      soulmate = true
      primary_type_updates["primary_type"] = name
    end

    if name_changed? || slug_changed? || url_pretty_changed?
      soulmate = true
    end

    #if short_name_changed?
    #  soulmate = true
    #end

    unless primary_type_updates.empty?
      Topic.where("primary_type_id" => id).each do |topic|
        unless topic.id == id
          topic.set_primary_type(name, id)
          topic.save
        end
      end
    end

    if soulmate
      neo4j_update
      Resque.enqueue(SmCreateTopic, id.to_s)
    end

    if score_changed?
      Resque.enqueue_in(10.minutes, ScoreUpdate, 'Topic', id.to_s)
    end
  end
end
