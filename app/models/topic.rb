require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Images
  include ImageHelper

  cache

  @type_of_id = "4eb82a1caaf9060120000081"
  @instances_id = "4eb82a3daaf906012000008a" # this is the opposite of type_of connection
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
  class << self; attr_accessor :type_of_id, :instances_id, :limelight_id, :limelight_feedback_id, :stop_words end

  # Denormilized:
  # Post.topic_mentions.name
  # TopicConnectionSnippet.topic_name
  field :name

  # Denormilized:
  # Topic.aliases
  # TopicMention.slug
  # TopicConnectionSnippet.topic_slug
  slug :name

  field :summary
  field :short_name
  field :health, :default => []
  field :health_index, :default => 0
  field :fb_id # freebase id
  field :fb_mid # freebase mid
  field :status, :default => 'active'
  field :slug_locked
  field :user_id
  field :followers_count, :default => 0
  field :response_count
  field :primary_type
  field :primary_type_id
  field :talking_ids, :default => []
  field :response_count, :default => 0
  field :influencers, :default => {}
  field :score, :default => 0.0

  auto_increment :public_id

  belongs_to :user
  embeds_many :aliases, :as => :has_alias, :class_name => 'TopicAlias'

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 50 }
  validates :short_name, :uniqueness => true, :unless => "short_name.blank?"
  validates_each :name do |record, attr, value|
    if Topic.stop_words.include?(value) || !Topic.deleted.where("aliases.slug" => value.parameterize).first.nil?
      record.errors.add attr, "is not permitted"
    end
  end

  attr_accessible :name, :summary, :aliases, :short_name

  before_create :init_alias, :text_health
  after_create :neo4j_create, :add_to_soulmate
  before_update :update_name_alias, :text_health
  after_update :update_denorms#, :expire_caches
  before_destroy :remove_from_soulmate, :disconnect#, :expire_caches

  index [[ :slug, Mongo::ASCENDING ]]
  index [[ :public_id, Mongo::DESCENDING ]]
  index [[ :score, Mongo::DESCENDING ]]
  index [[ :short_name, Mongo::ASCENDING ]]
  index :aliases
  index :primary_type_id

  # Return the topic slug instead of its ID
  def to_param
    self.slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  def title
    name
  end

  def title_clean
    name
  end

  #
  # Aliases
  #

  def init_alias
    self.aliases ||= []
    add_alias(name)
    plurl = name.pluralize == name ? name.singularize : name.pluralize
    add_alias(plurl)
    add_alias(short_name) unless !short_name || short_name.blank?
  end

  def get_alias name
    self.aliases.detect{|a| a.slug == name.to_url}
  end

  def add_alias(new_alias, ooac=false)
    return unless new_alias && !new_alias.blank?

    unless get_alias new_alias
      existing = Topic.where('aliases.slug' => new_alias.to_url, 'ooac' => true).first
      if existing
        return "The '#{existing.name}' topic has a one of a kind alias with this name."
      else
        self.aliases << TopicAlias.new(:name => new_alias, :slug => new_alias.to_url, :hash => new_alias.to_url.gsub('-', ''), :ooac => ooac)
        Resque.enqueue(SmCreateTopic, id.to_s)
        return true
      end
    else
      'This topic already has that alias.'
    end
  end

  def remove_alias old_alias
    return unless old_alias && !old_alias.blank?
    new_aliases = []
    aliases.each do |a|
      if a.slug != old_alias.to_url
        new_aliases << a
      end
    end
    self.aliases = new_aliases
  end

  def update_alias(alias_id, name, ooac)
    found = self.aliases.detect{|a| a.id.to_s == alias_id}
    if found
      if ooac == true
        existing = Topic.where('aliases.slug' => name.to_url).to_a
        if existing.length > 1
          names = []
          existing.each {|t| names << t.name if t.id != id}
          names = names.join(', ')
          return "The '#{names}' topic already have an alias with this name."
        end
      end
      found.name = name if name
      found.slug = name.to_url if name
      found.ooac = ooac
    end
    true
  end

  # not used?
  def update_aliases new_aliases
    self.aliases = []
    init_alias

    new_aliases = new_aliases.split(', ') unless new_aliases.is_a? Array
    new_aliases.each do |new_alias|
      add_alias(new_alias)
    end
  end

  def update_name_alias
    if short_name_changed?
      update_aliases(also_known_as)
      remove_alias(short_name_was)
      add_alias(short_name)
    end
    if name_changed?
      remove_alias(name_was.pluralize)
      remove_alias(name_was.singularize)
      add_alias(name.pluralize)
      add_alias(name.singularize)
    end
  end

  def has_alias? name
    aliases.detect {|data| data.slug == name.to_url}
  end

  def also_known_as
    also_known_as = Array.new
    aliases.each do |also|
      if also.slug != name.to_url && also.slug != name.pluralize.to_url && also.slug != name.singularize.to_url && also.slug != short_name
        also_known_as << also.name
      end
    end
    also_known_as
  end

  class << self
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end
  end

  #
  # Health
  #

  def text_health
    self.health ||= []
    if summary_changed? || short_name_changed?
      update_health('summary') if !summary.blank?
      update_health('short_name') if !short_name.blank?
      self.health_index = health.length
    end
  end

  def update_health(attr)
    self.health ||= []
    if !health.include?(attr)
      self.health << attr
      self.health_index = health.length
    end
  end

  def remove_health(attr)
    self.health ||= []
    if health.include?(attr)
      self.health.delete(attr)
      self.health_index = health.length
    end
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
    update_health('type')
    if !primary_type || !primary_type_id
      self.primary_type = primary_name
      self.primary_type_id = primary_id
      Resque.enqueue(SmCreateTopic, id.to_s)
    end
  end

  def unset_primary_type
    self.primary_type = nil
    self.primary_type_id = nil
    Resque.enqueue(SmCreateTopic, id.to_s)
    remove_health('type')
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
    topic_mention_updates["topic_mentions.$.public_id"] = public_id
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

    # PUSH FEEDS
    FeedTopicItem.collection.update(
            { "mentions" => aliased_topic.id },
            {
                    "$set" => { "mentions.$" => id },
                    "$rename" => {"responses."+aliased_topic.id.to_s => "responses."+id.to_s}
            },
            {:multi => true}
    )
    FeedTopicItem.collection.update(
            { "root_mentions" => aliased_topic.id},
            { "$set" => {"root_mentions.$" => id}},
            {:multi => true}
    )
    FeedLikeItem.collection.update(
            { "root_id" => aliased_topic.id },
            { "$set" => {:root_id => id}},
            {:multi => true}
    )
    FeedContributeItem.collection.update(
            { "root_id" => aliased_topic.id },
            { "$set" => {:root_id => id}},
            {:multi => true}
    )

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

  # BETA REMOVE
  #def expire_caches
  #  Topic.expire_caches(id.to_s)
  #
  #  # if name/slug changed clear any cached thing with links to this topic
  #  if name_changed? || slug_changed? || short_name_changed?
  #    objects = Post.where('topic_mentions._id' => id)
  #    objects.each do |object|
  #      object.expire_caches
  #    end
  #    ActionController::Base.new.expire_cell_state TopicCell, :trending
  #  end
  #end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'topic', 'name' => name, 'slug' => slug, 'public_id' => public_id)
    Neo4j.neo.add_node_to_index('topics', 'uuid', id.to_s, node)
  end

  def neo4j_update
    node = Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
    Neo4j.neo.set_node_properties(node, {'name' => name, 'slug' => slug})
  end

  def disconnect
    # remove mentions of this topic
    Post.where("topic_mentions._id" => id).each do |object|
      object.remove_topic_mentions_of(id)
    end

    # remove from neo4j
    node = Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
    Neo4j.neo.delete_node!(node)

    # reset primary types
    Topic.where('primary_type_id' => id).each do |topic|
      topic.unset_primary_type
      #topic.expire_caches BETA REMOVE
      topic.save
    end
  end

  def user_influence(id)
    influencers[id.to_s]["influence"] if influencers[id.to_s]
  end
  def user_percentile(id)
    influencers[id.to_s]["percentile"] if influencers[id.to_s]
  end

  class << self

    # Checks if there is an untyped topic with an alias equal to the name. If so, returns that topic, if not, returns new topic
    def find_untyped_or_create(name, user)
      alias_topic = Topic.where("aliases.slug" => name.to_url, "primary_type_id" => {"$exists" => false}).first
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
        matches = Topic.where(:status => 'active').any_of({:short_name => {'$in' => (with_counts ? word_combos.keys : word_combos)}}, {'aliases.hash' => hash_query}).order_by([[:pm, :desc]])
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

    # BETA REMOVE
    #def expire_caches(target_id)
    #  # topic right sidebar
    #  ActionController::Base.new.expire_cell_state TopicCell, :sidebar, target_id.to_s
    #  ['-following', '-manage', '-following-manage'].each do |key|
    #    ActionController::Base.new.expire_cell_state TopicCell, :sidebar, target_id.to_s+key
    #  end
    #end
  end

  protected

  #TODO: check that soulmate gets updated if this topic is a type for another topic
  def update_denorms
    soulmate = nil
    topic_mention_updates = {}
    primary_type_updates = {}
    if name_changed?
      soulmate = true
      topic_mention_updates["topic_mentions.$.name"] = self.name
      primary_type_updates["primary_type"] = name
    end
    if slug_changed?
      soulmate = true
      topic_mention_updates["topic_mentions.$.slug"] = self.slug
    end
    if short_name_changed?
      soulmate = true
      objects = Post.where('topic_mentions.id' => id)
      objects.each do |object|
        object.name.gsub!(/\##{short_name_was}/, "##{short_name}")
        object.content.gsub!(/\##{short_name_was}/, "##{short_name}")
        existing = object.topic_mentions.detect{|mention| mention.id == id}
        if existing
          existing.short_name = short_name
        end
        object.save
      end
    end

    unless topic_mention_updates.empty?
      Post.where("topic_mentions._id" => id).update_all(topic_mention_updates)
    end
    unless primary_type_updates.empty?
      Topic.where("primary_type_id" => id).update_all(primary_type_updates)
    end

    if soulmate
      neo4j_update
      Resque.enqueue(SmCreateTopic, id.to_s)
    end
  end
end
