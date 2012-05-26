require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps::Updated
  include Limelight::Acl
  include Limelight::Images
  include ImageHelper

  include ModelUtilitiesHelper

  cache

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
  field :freebase_guid
  field :freebase_id
  field :freebase_url
  field :use_freebase_image, :default => false
  field :wikipedia
  field :website
  field :websites_extra, :default => []
  field :neo4j_id
  field :is_category, :default => false

  auto_increment :public_id

  belongs_to :user
  embeds_many :aliases, :as => :has_alias, :class_name => 'TopicAlias'

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 50 }
  validates :short_name, :uniqueness => true, :unless => "short_name.blank?"
  validates_each :name do |record, attr, value|
    if Topic.stop_words.include?(value) || !Topic.deleted.where("aliases.slug" => value.to_url).first.nil?
      record.errors.add attr, "This topic name is not permitted."
    end
  end

  attr_accessible :name, :summary, :aliases, :short_name

  before_create :init_alias
  after_create :neo4j_create, :add_to_soulmate, :fetch_external_data
  before_update :update_name_alias
  after_update :update_denorms
  before_destroy :remove_from_soulmate, :disconnect

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

  def created_at
    id.generation_time
  end

  def title
    name
  end

  def freebase_guid
    if read_attribute(:freebase_guid)
      "/guid/#{read_attribute(:freebase_guid).split('.').last}"
    end
  end

  def fetch_external_data
    Resque.enqueue(TopicFetchExternalData, id.to_s)
  end

  def fetch_freebase(overwrite_text=false, overwrite_aliases=false, overwrite_primary_type=false, overwrite_image=false)
    # get or find the freebase object
    freebase_search = nil
    if freebase_guid || freebase_id
      freebase_object = freebase_guid ? Ken::Topic.get(freebase_guid) : Ken::Topic.get(freebase_id)

      return unless freebase_object

      search = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&limit=1&query=#{URI::encode(name)}")

      # make sure the names match up at least a little bit
      if search && search['result'] && search['result'].first && ((search['result'].first['notable'] && search['result'].first['score'] >= 75) || search['result'].first['score'] >= 800)
        search['result'].each do |s|
          if s['name'].to_url.include?(name.to_url) && s['score'] >= 75
            freebase_search = s
            break
          end
        end
        unless freebase_search
          freebase_search = search['result'].first
          freebase_search = nil unless (search['result'].first['name'].to_url.include?(name.to_url) && search['result'].first['score'] > 150) || search['result'].first['score'] >= 1500
        end
      end
    else
      search = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&limit=3&query=#{URI::encode(name)}")
      return unless search && search['result'] && search['result'].first && ((search['result'].first['notable'] && search['result'].first['score'] >= 75) || search['result'].first['score'] >= 800)

      search['result'].each do |s|
        if s['name'].to_url == name.to_url && s['score'] >= 75
          freebase_search = s
          break
        end
      end
      # make sure the names match up at least a little bit
      unless !search || freebase_search
        return unless (search['result'].first['name'].to_url.include?(name.to_url) && search['result'].first['score'] > 150) || search['result'].first['score'] >= 1500
        freebase_search = search['result'].first
      end

      freebase_object = Ken::Topic.get(freebase_search['mid'])
      return unless freebase_object

      existing_topic = Topic.where(:freebase_id => freebase_object.id).first
      return if existing_topic && existing_topic.id != id
    end

    # basics
    self.freebase_id = freebase_object.id
    self.freebase_url = freebase_object.url
    self.summary = freebase_object.description unless summary

    # store extra websites
    freebase_object.webpages.each do |w|
      if w['text'] == '{name}'
        self.website = w['url']
      elsif ['Wikipedia','New York Times','Crunchbase'].include?(w['text']) && !websites_extra.detect{|we| we['name'] == w['text']}
        self.websites_extra << {
                'name' => w['text'],
                'url' => w['url']
        }
      end
    end

    # try to connect types
    type_connection = TopicConnection.find(Topic.type_of_id)
    if freebase_search && freebase_search['notable'] && (overwrite_primary_type || !primary_type_id)
      type_topic = Topic.where("aliases.slug" => freebase_search['notable']['name'].to_url).first
      unless type_topic
        type_topic = Topic.new
        type_topic.name = freebase_search['notable']['name']
        type_topic.user_id = User.marc_id
        type_topic.save
      end
      set_primary_type(type_topic.name, type_topic.id)
      TopicConnection.add(type_connection, self, type_topic, User.marc_id, {:pull => false, :reverse_pull => true})
    elsif freebase_object.types && freebase_object.types.length > 0
      type_names = freebase_object.types.map{|t| t.name.to_url}
      type_topics = Topic.where("aliases.slug" => {"$in" => type_names}, :is_topic_type => true).to_a
      type_topics.each do |t|
        next if primary_type_id || primary_type_id == t.id
        set_primary_type(t.name, t.id) unless primary_type_id
        TopicConnection.add(type_connection, self, t, User.marc_id, {:pull => false, :reverse_pull => true})
      end
    end

    # update the image
    if image_versions == 0 || overwrite_image
      self.active_image_version = 0
      self.use_freebase_image = true
    end

    # overwrite certain things
    if overwrite_text
      existing_name = Topic.where(:name => freebase_object.name, :primary_type_id => {"$exists" => false}).first
      self.name = freebase_object.name unless existing_name
      self.summary = freebase_object.description
    end

    if overwrite_aliases && freebase_object.aliases.length > 0
      self.aliases = []
      init_alias
      freebase_object.aliases.each do |a|
        add_alias(a)
      end
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

  def get_alias name
    self.aliases.detect{|a| a.slug == name.to_url}
  end

  def add_alias(new_alias, ooac=false, hidden=false)
    return unless new_alias && !new_alias.blank?

    unless get_alias new_alias
      #existing = Topic.where('aliases.slug' => new_alias.to_url, 'ooac' => true).first
      #if existing
      #  return "The '#{existing.name}' topic has a one of a kind alias with this name."
      #else
        self.aliases << TopicAlias.new(:name => new_alias, :slug => new_alias.to_url, :hash => new_alias.to_url.gsub('-', ''), :ooac => ooac, :hidden => hidden)
        Resque.enqueue(SmCreateTopic, id.to_s)
        return true
      #end
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
    Resque.enqueue(SmCreateTopic, id.to_s)
  end

  def update_alias(alias_id, name, ooac, hidden=false)
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
      found.name = name unless name.blank?
      found.slug = name.to_url unless name.blank?
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
    if short_name_changed?
      update_aliases(also_known_as)
      remove_alias(short_name_was)
      add_alias(short_name)
    end
    if name_changed?
      if name_was
        remove_alias(name_was.pluralize)
        remove_alias(name_was.singularize)
      end
      add_alias(name.pluralize, false, true)
      add_alias(name.singularize, false, true)
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
      self.primary_type = primary_name
      self.primary_type_id = primary_id
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

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'topic', 'name' => name, 'slug' => slug, 'created_at' => created_at.to_i, 'score' => score)
    Neo4j.neo.add_node_to_index('topics', 'uuid', id.to_s, node)
    self.neo4j_id = node['self'].split('/').last
    save
    node
  end

  def neo4j_update
    node = Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
    Neo4j.neo.set_node_properties(node, {'name' => name, 'slug' => slug})
  end

  def neo4j_node
    Neo4j.neo.get_node_index('topics', 'uuid', id.to_s)
  end

  def disconnect
    # remove mentions of this topic (also removes from user feeds)
    Post.where("topic_mentions._id" => id).each do |object|
      object.remove_topic_mention(self)
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
    User.collection.update({:following_topics => id}, {"$pull" => {"following_topics" => id}, "$inc" => {"following_topics_count" => -1}})

    # remove from topic feeds
    FeedTopicItem.topic_destroy(self)

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

  def as_json(options={})
    {
            :id => id.to_s,
            :slug => to_param,
            :type => 'Topic',
            :name => name,
            :summary => short_summary,
            :score => score,
            :followers_count => followers_count,
            :created_at => created_at.to_i,
            :created_at_pretty => pretty_time(created_at),
            :images => Topic.json_images(self),
            :primary_type => primary_type,
            :aliases => visible_aliases,
            :websites => all_websites,
            :freebase_url => freebase_url

    }
  end

  class << self

    def json_images(model)
      {
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

    if name_changed? || slug_changed? || slugged_attributes_changed?
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

    if image_versions_changed? || active_image_version_changed?
      topic_mention_updates["topic_mentions.$.image_versions"] = self.image_versions
      topic_mention_updates["topic_mentions.$.active_image_version"] = self.active_image_version
    end

    if use_freebase_image_changed?
      topic_mention_updates["topic_mentions.$.use_freebase_image"] = self.use_freebase_image
    end

    if freebase_id_changed?
      topic_mention_updates["topic_mentions.$.freebase_id"] = self.freebase_id
    end

    unless topic_mention_updates.empty?
      Post.where("topic_mentions._id" => id).update_all(topic_mention_updates)
    end

    unless primary_type_updates.empty?
      Topic.where("primary_type_id" => id).each do |topic|
        topic.set_primary_type(name, id)
        topic.save
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
