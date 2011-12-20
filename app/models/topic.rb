require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Images
  include Limelight::Popularity

  @type_of_id = "4eb82a1caaf9060120000081"
  @instances_id = "4eb82a3daaf906012000008a" # this is the opposite of type_of connection
  @limelight_id = '4ec69d9fcddc7f9fe80000b8'
  @limelight_feedback_id = '4ecab6c1cddc7fd77f000106'
  class << self; attr_accessor :type_of_id, :instances_id, :limelight_id, :limelight_feedback_id end

  # Denormilized:
  # CoreObject.topic_mentions.name
  # TopicConnectionSnippet.topic_name
  field :name

  # Denormilized:
  # Topic.aliases
  # TopicMention.slug
  # TopicConnectionSnippet.topic_slug
  slug :name, :v do |doc|
    if doc.slug_locked
      doc.slug
    else
      if doc.get_primary_types.empty?
        doc.name
      else
        doc.name + " " + doc.get_primary_types[0].topic_name.to_url
      end
    end
  end

  field :summary
  field :short_name
  field :health, :default => []
  field :health_index, :default => 0
  field :fb_img, :default => false # use the freebase image?
  field :fb_id # freebase id
  field :fb_mid # freebase mid
  field :status, :default => 'active'
  field :slug_locked
  field :user_id
  field :followers_count, :default => 0
  field :v, :default => 1

  auto_increment :public_id

  belongs_to :user
  embeds_many :topic_connection_snippets
  embeds_many :aliases, :as => :has_alias, :class_name => 'TopicAlias'

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 50 }
  validates :short_name, :uniqueness => true, :unless => "short_name.blank?"
  attr_accessible :name, :summary, :aliases, :short_name

  before_create :init_alias, :text_health
  after_create :add_to_soulmate
  before_update :update_name_alias, :text_health
  after_update :update_denorms, :expire_caches
  before_destroy :remove_from_soulmate

  index [[ :slug, Mongo::ASCENDING ]]
  index "aliases.slug"
  index "aliases.hash"
  index :short_name
  index :ph
  index :pd
  index :pw
  index :pm
  index :pt

  # Return the topic slug instead of its ID
  def to_param
    self.slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
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
  # Merge
  #

  def merge(aliased_topic)
    self.aliases = aliases + aliased_topic.aliases

    # Update topic mentions
    objects = CoreObject.where("topic_mentions._id" => aliased_topic.id)
    objects.each do |object|
      # if an object mentions both, delete the old one
      if object.mentions?(aliased_topic.id) && object.mentions?(id)
        object.topic_mentions.destroy_all(conditions: { id: aliased_topic.id })
      end
      object.content = object.content.gsub(aliased_topic.id.to_s, id.to_s)
      object.save!
    end

    topic_mention_updates = {}
    topic_mention_updates["topic_mentions.$.name"] = name
    topic_mention_updates["topic_mentions.$.slug"] = slug
    topic_mention_updates["topic_mentions.$._id"] = id
    topic_mention_updates["topic_mentions.$.public_id"] = public_id
    CoreObject.where("topic_mentions._id" => aliased_topic.id).update_all(topic_mention_updates)

    # Move Connections
    aliased_connection_snippets = aliased_topic.topic_connection_snippets.dup
    topic_ids = aliased_connection_snippets.map { |snippet| snippet.topic_id }
    topics = Topic.where(:_id.in => topic_ids)

    aliased_connection_snippets.each do |snippet|
      topic = topics.detect {|topic| topic.id == snippet.topic_id }
      connection = TopicConnection.find(snippet.id)
      aliased_topic.remove_connection(connection, topic)
      add_connection(connection, topic, snippet.user_id)
    end

    # Following
    followers = User.where(:following_topics => aliased_topic.id)
    followers.each do |follower|
      follower.unfollow_topic aliased_topic
      follower.follow_topic self
      follower.save
    end

    # TODO:
    Resque.enqueue(SmCreateTopic, id.to_s)
    Resque.enqueue(SmDestroyTopic, aliased_topic.id.to_s)
  end

  #
  # Connections
  #

  # Returns true if the topic has one type_of or instances connection
  def typed?
    topic_connection_snippets.any?{ |snippet| snippet.id.to_s == Topic.type_of_id } ||
          topic_connection_snippets.any?{ |snippet| snippet.id.to_s == Topic.instances_id }
  end

  def has_connection?(con_id, con_topic_id)
    topic_connection_snippets.any?{ |snippet| snippet.topic_id == con_topic_id && snippet.id == con_id }
  end

  def add_connection(connection, con_topic, user_id, primary=false)
    if !connection.opposite.blank? && opposite = TopicConnection.find(connection.opposite)
      con_topic.add_connection_helper(opposite, self, user_id, primary)
    end
    self.add_connection_helper(connection, con_topic, user_id, primary)
  end

  def add_connection_helper(connection, con_topic, user_id, primary)
    if self.has_connection?(connection.id, con_topic.id)
      false
    else
      snippet = TopicConnectionSnippet.new()
      snippet.id = connection.id
      snippet.name = connection.name
      snippet.pull_from = connection.pull_from
      snippet.topic_id = con_topic.id
      snippet.topic_name = con_topic.name
      snippet.topic_slug = con_topic.slug
      snippet.user_id = user_id
      if connection.id.to_s == Topic.type_of_id && (primary || get_primary_types.empty?)
        snippet.primary = true
        update_health("type")
        self.v += 1
      end
      if connection.id.to_s != Topic.type_of_id
        update_health("connection")
      end
      self.topic_connection_snippets << snippet
      true
    end
  end

  def remove_connection(connection, con_topic)
    remove_connection_helper(connection, con_topic)
    if !connection.opposite.blank? && opposite = TopicConnection.find(connection.opposite)
      con_topic.remove_connection_helper(opposite, self)
    end
  end

  def remove_connection_helper(connection, con_topic)
    # Update the collection directly since deletion from the array was not persisting to DB
    Topic.collection.update({:_id => id}, {'$pull' => {'topic_connection_snippets' => {:topic_id => con_topic.id, :_id => connection.id}}})
    # Also delete from the current record so that the slug gets updated correctly
    topic_connection_snippets.delete_if { |snippet| snippet.topic_id == con_topic.id && snippet.id == connection.id }

    if connection.id.to_s == Topic.type_of_id
      self.v += 1
    end
  end

  # Gets connections, returning a hash of the following format
  # connections => {:connection_id => {:name => "ConnectionName", :topics => [topic1, topic2]}}
  def get_connections
    topic_ids = topic_connection_snippets.map { |snippet| snippet.topic_id }
    topics = Topic.where(:_id.in => topic_ids).desc(:pt)
    connections = {}

    topics.each do |topic|
      topic_connection_snippets.each do |snippet|
        if topic.id == snippet.topic_id
          connections[snippet.id] ||= {:name => snippet.name, :data => []}
          connections[snippet.id][:data] << {:snippet => snippet, :topic => topic}
        end
      end
    end

    connections
  end

  # recursively gets topic ids to pull from in a hash of format {:topic_id => true}
  def pull_from_ids(ids)
    topic_connection_snippets.each do |snippet|
      if snippet.pull_from? && !ids.include?(snippet.topic_id)
        ids << snippet.topic_id
        topic = Topic.find(snippet.topic_id)
        ids = ids.merge(topic.pull_from_ids(ids)) if topic
      end
    end
    ids
  end

  # TODO: finish
  # Suggests connections for the topic based on other topics of the same type(s)
  def suggested_connections
    similar_topic_ids = []
    con_ids = []
    type_ids = get_types.map { |snippet| snippet.topic_id }
    type_topics = Topic.where("_id" => { "$in" => type_ids })
    type_topics.each_with_index do |type_topic, i|
      similar_topic_ids = similar_topic_ids | type_topic.get_instances.map { |snippet| snippet.topic_id }
    end

    topics = Topic.where("_id" => { "$in" => similar_topic_ids })
    topics.each do |topic|
      con_ids = con_ids | topic.get_connection_ids
    end

    TopicConnection.where("_id" => { "$in" => con_ids })
  end

  def get_types
    topic_connection_snippets.select { |snippet| snippet.id.to_s == Topic.type_of_id }
  end

  def get_primary_types
    topic_connection_snippets.select { |snippet| (snippet.id.to_s == Topic.type_of_id) && snippet.primary }
  end

  def get_instances
    topic_connection_snippets.select { |snippet| snippet.id.to_s == Topic.instances_id }
  end

  def get_connection_ids
    topic_connection_snippets.map{ |snippet| snippet.id }.uniq
  end

  class << self

    # find mentions in a body of text and return the topic matches
    # optionally return how often the mention occured in the text
    def parse_text(text, ooac=true, with_counts=nil)
      words = text.split(' ')
      word_combos = with_counts ? {} : []
      words.length.times do |i|
        5.times do |x|
          word = ''
          x.times do |y|
            word += words[i+y].tr('^A-Za-z0-9', '').downcase if words[i+y]
          end
          unless word.blank?
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
        matches = Topic.any_of({:short_name => {'$in' => (with_counts ? word_combos.keys : word_combos)}}, {'aliases.hash' => hash_query}).to_a
      else
        matches = []
      end

      if with_counts
        processed_matches = {}
        matches.each do |match|
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
        matches = processed_matches
      end

      matches
    end

    # given topic mentions, grab and rank their connections in the graph
    def get_graph(data, depth=1)
      tmp = data.dup

      # build the counts
      connection_ids = []
      tmp.each do |topic_id, data_point|
        data_point[:topic].topic_connection_snippets.each do |connection|
          unless connection.id.to_s == Topic.type_of_id
            unless data[connection.topic_id.to_s]
              connection_ids << connection.topic_id
              data[connection.topic_id.to_s] ||= {:topic => nil, :connection => connection, :count => 0}
            end
            data[connection.topic_id.to_s][:count] += 1
          end
        end
      end

      # replace the connections with topics
      topics = Topic.where(:_id => {'$in' => connection_ids})
      topics.each do |t|
        data[t.id.to_s][:topic] = t
      end

      # update the scores
      data.each do |topic_id, data_point|
        data_point[:score] = data_point[:count].to_i * (data_point[:topic][:pt] == 0 ? 1 : data_point[:topic][:pt].to_i)
      end

      # sort the data
      data.sort_by {|topic_id, d| (-1)*d[:score]}

      data
    end
  end

  protected

  #TODO: check that soulmate gets updated if this topic is a type for another topic
  def update_denorms
    soulmate = nil
    topic_mention_updates = {}
    connection_snippet_updates = {}
    if name_changed?
      soulmate = true
      topic_mention_updates["topic_mentions.$.name"] = self.name
      connection_snippet_updates["topic_connection_snippets.$.topic_name"] = self.name
    end
    if slug_changed?
      soulmate = true
      topic_mention_updates["topic_mentions.$.slug"] = self.slug
      connection_snippet_updates["topic_connection_snippets.$.topic_slug"] = self.slug
    end
    if short_name_changed?
      soulmate = true
      objects = CoreObject.where('topic_mentions.id' => id)
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

    unless connection_snippet_updates.empty?
      CoreObject.where("topic_mentions._id" => id).update_all(topic_mention_updates)
      Topic.where("topic_connection_snippets.topic_id" => id).update_all(connection_snippet_updates)

      # Updates v attribute of instances so they update their slugs
      instance_ids = get_instances.map{|instance| instance.topic_id}
      if instance_ids
        instances = Topic.where("_id" => { "$in" => instance_ids })
        instances.each do |instance|
          instance.v += 1
          instance.save
        end
      end
      #TODO: change above to be more effiecient? need to get affected topics to update their slug if necessary
      #Topic.collection.update({"topic_connection_snippets.topic_id" => id},
      #                        { "$set" => connection_snippet_updates,
      #                          "$inc" => { "v" => 1 } }, false, true)
    end

    if soulmate
      Resque.enqueue(SmCreateTopic, id.to_s)
    end
  end

  def expire_caches
    # topic right sidebar
    ['', '-following', '-manage', '-following-manage'].each do |key|
      ActionController::Base.new.expire_cell_state TopicCell, :sidebar_right, id.to_s+key
    end

    # if name/slug changed clear any cached thing with links to this topic
    if name_changed? || slug_changed? || short_name_changed?
      objects = CoreObject.where('topic_mentions._id' => id)
      objects.each do |object|
        object.expire_caches
      end
      ActionController::Base.new.expire_cell_state TopicCell, :trending
    end
  end
end
