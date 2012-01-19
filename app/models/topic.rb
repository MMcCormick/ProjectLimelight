require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Images
  include Limelight::Popularity
  include ImageHelper

  @type_of_id = "4eb82a1caaf9060120000081"
  @instances_id = "4eb82a3daaf906012000008a" # this is the opposite of type_of connection
  @limelight_id = '4ec69d9fcddc7f9fe80000b8'
  @limelight_feedback_id = '4ecab6c1cddc7fd77f000106'
  @stop_words = ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't",
                 "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "can't",
                 "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down",
                 "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't",
                 "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself",
                 "his", "how", "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it",
                 "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not",
                 "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "	ourselves", "out", "over",
                 "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such",
                 "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's",
                 "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too",
                 "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were",
                 "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's",
                 "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've",
                 "your", "yours", "yourself", "yourselves"]
  class << self; attr_accessor :type_of_id, :instances_id, :limelight_id, :limelight_feedback_id, :stop_words end

  # Denormilized:
  # CoreObject.topic_mentions.name
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
  field :primary_type

  auto_increment :public_id

  belongs_to :user
  embeds_many :topic_connection_snippets
  embeds_many :aliases, :as => :has_alias, :class_name => 'TopicAlias'

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 50 }
  validates :short_name, :uniqueness => true, :unless => "short_name.blank?"
  validates_each :name do |record, attr, value|
    record.errors.add attr, "is not permitted" if Topic.stop_words.include?(value)
  end

  attr_accessible :name, :summary, :aliases, :short_name

  before_create :init_alias, :text_health
  after_create :neo4j_create, :add_to_soulmate
  before_update :update_name_alias, :text_health
  after_update :update_denorms, :expire_caches
  before_destroy :remove_from_soulmate

  index [[ :slug, Mongo::ASCENDING ]]
  index "aliases.slug"
  index "aliases.hash"
  index :short_name
  index :primary_type
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

    Resque.enqueue(SmCreateTopic, id.to_s)
    Resque.enqueue(SmDestroyTopic, aliased_topic.id.to_s)
  end

  def raw_image(w,h,m)
    url = default_image_url(self, w, h, m, true)
    url = Rails.public_path+url if Rails.env.development?
    url
  end

  def expire_caches
    Topic.expire_caches(id.to_s)

    # if name/slug changed clear any cached thing with links to this topic
    if name_changed? || slug_changed? || short_name_changed?
      objects = CoreObject.where('topic_mentions._id' => id)
      objects.each do |object|
        object.expire_caches
      end
      ActionController::Base.new.expire_cell_state TopicCell, :trending
    end
  end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'topic', 'name' => name, 'slug' => slug, 'public_id' => public_id)
    Neo4j.neo.add_node_to_index('topics', 'uuid', id.to_s, node)
  end

  def neo4j_update
    node = Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
    Neo4j.neo.set_node_properties(node, {'name' => name, 'slug' => slug})
  end

  class << self

    # Checks if there is an untyped topic with an alias equal to the name. If so, returns that topic, if not, returns new topic
    def find_untyped_or_create(name, user)
      alias_topic = Topic.where("aliases.slug" => name.to_url, "primary_type" => {"$exists" => false}).first
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

    def expire_caches(target_id)
      # topic right sidebar
      ActionController::Base.new.expire_cell_state TopicCell, :sidebar, target_id.to_s
      ['-following', '-manage', '-following-manage'].each do |key|
        ActionController::Base.new.expire_cell_state TopicCell, :sidebar, target_id.to_s+key
      end
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
    end

    if soulmate
      neo4j_update
      Resque.enqueue(SmCreateTopic, id.to_s)
    end
  end
end
