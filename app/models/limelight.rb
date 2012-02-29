#require 'RMagick'
#include Magick

# encoding: utf-8
module Limelight #:nodoc:

  # Include this module to get ACL functionality for root level documents.
  # @example Add ACL support to a document.
  #   require "limelight"
  #   class Person
  #     include Limelight::Acl
  #   end
  module Acl
    extend ActiveSupport::Concern

    included do
      field :permissions, :default => {}
    end

    # @example Check to see if the object with the given MongoId has a given permission on this document
    #   document.permission?
    #
    # @param [ Mongoid ] The MongoId of the object requesting permission
    # @param [ String ] The permission to check
    #
    # @return [ bool ]
    def permission?(object_id, permission)
      permissions and permissions.instance_of? BSON::OrderedHash and permissions.has_key?(permission.to_s) and permissions[permission.to_s].include?(object_id)
    end

    # @example Allow the given MongoId to edit & delete this document
    #   document.grant_owner
    #
    # @param [ Mongoid ] The MongoId of the object to grant ownership
    #
    # @return [ bool ]
    def grant_owner(object_id)
      self.grant_permission(object_id, "update")
      self.grant_permission(object_id, "destroy")
    end

    # @example Allow the given MongoId to edit this document
    #   document.grant_edit
    #
    # @param [ Mongoid ] The MongoId of the object to grant permission
    # @param [ String|Array ] The permission(s) to grant
    #
    # @return [ bool ]
    def grant_permission(object_id, permission)
      permission = [permission] unless permission.kind_of?(Array)

      permission.each do |p|
        self.permissions[p] ||= []
        self.permissions[p] << object_id unless self.permissions[p].include?(object_id)
      end
    end

    # @example Revoke the given permission(s) from this document
    #   document.revoke_permission
    #
    # @param [ Mongoid ] The MongoId of the object to revoke permission
    # @param [ String|Array ] The permission(s) to revoke
    #
    # @return [ bool ]
    def revoke_permission(object_id, permission)
      permission = [permission] unless permission.kind_of?(Array)

      permission.each do |p|
        if self.permissions[p]
          self.permissions[p].delete(object_id)
        end
      end
    end
  end

  # Include this module to enable image handling on a document
  # @example Add image handling.
  #   require "limelight"
  #   class Person
  #     include Limelight::Images
  #   end
  module Images
    extend ActiveSupport::Concern

    included do
      embeds_many :images, as: :image_assignable, :class_name => 'ImageSnippet'

      attr_accessible :asset_image
      attr_accessor :asset_image
    end

    def save_images
      self.images.each do |image|
        image.versions.each do |version|
          version.save
        end
      end
    end

    # @return AssetImage
    def default_image
      images.each do |image|
        return image if image.isDefault?
      end
    end

    def available_dimensions
      [[30,30],[40,40],[50,50],[60,60],[65,65],[75,75],[100,100],[150,150],[180, 0]]
    end

    def available_modes
      ['fillcropmid', 'fit']
    end

    def add_image(user_id, image_location)
      image = self.images.create(:user_id => user_id)
      version = AssetImage.new(:isOriginal => true)
      version.id = image.id
      version.save_image(image_location)
      image.versions << version
      version.save
      image
    end

    def add_image_version(image_id, dimensions, mode)
      image = self.images.find(image_id)

      if image && image.original && image.original.first
        original = image.original.first.image.file
        if original.path && File.exists?(original.path)
          new_image = Image.from_blob(original.read).first

          width = dimensions[0] == 0 ? 999999 : dimensions[0]
          height = dimensions[1] == 0 ? 999999 : dimensions[1]

          case mode
            when 'fillcropmid'
              new_image = new_image.resize_to_fill(width, height)
            when 'fit'
              new_image = new_image.resize_to_fit(width, height)
            else
              new_image = new_image.resize_to_fit(width, height)
          end

          upload_type = original.class.name
          if upload_type.include? 'Fog'
            filename = original.attributes[:key].split('/')
            filename = filename[-1]
          else
            filename = original.filename
          end

          tmp_location = "/tmp/d#{dimensions[0]}x#{dimensions[1]}_#{filename}"
          new_image.write tmp_location
          version = AssetImage.new(:isOriginal => false, :resizedTo => "#{dimensions[0]}x#{dimensions[1]}", :mode => mode, :width => new_image.columns, :height => new_image.rows)
          version.id = image.id
          version.image.store!(File.open(tmp_location))
          image.versions << version
          version.save
        end
      end
    end

    def set_default_image(image_id)
      images.each do |image|
        if image.id == image_id
          image.isDefault = true
        else
          image.isDefault = false
        end
      end
    end

    def save_original_image
      if valid? && @asset_image && (!@asset_image[:remote_image_url].blank? || !@asset_image[:image_cache].blank?)
        # Create/attach the links image
        image_snippet = ImageSnippet.new
        image_snippet.user_id = user.id
        image_snippet.add_uploaded_version(@asset_image, true)
        self.images << image_snippet
      end
    end
  end

  # Include this module to enable voting on a document
  # @example Add image handling.
  #   require "limelight"
  #   class Person
  #     include Limelight::Voting
  #   end
  module Voting
    extend ActiveSupport::Concern

    included do
      field :votes_count, :default => 0

      embeds_many :votes, as: :votable
    end

    # Votes
    def voter?(user_id, amount=nil)
      if amount
        vote = votes.where(:_id => user_id, :amount => amount).first
      elsif
        vote = votes.where(:_id => user_id).first
      end
      vote
    end

    def add_voter(user, amount)
      vote = voter? user.id
      net = nil
      if !vote
        self.votes.create(:_id => user.id, :amount => amount)
        self.votes_count += amount
        if amount > 0
          user.vote_pos_count += 1
          net = 1
        else
          user.vote_neg_count += 1
          net = -1
        end
      elsif vote.amount != amount
        self.votes_count = votes_count - vote.amount + amount
        vote.amount = amount
        if amount > 0
          user.vote_pos_count += 1
          user.vote_neg_count -= 1
          net = 2
        else
          user.vote_pos_count -= 1
          user.vote_neg_count += 1
          net = -2
        end
      end
      user.recalculate_vote_ratio
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, net)
      net
    end

    def remove_voter(user)
      vote = voter? user.id
      net = 0
      if vote
        if vote.amount > 0
          user.vote_pos_count -= 1
          net = -1
        else
          user.vote_neg_count -= 1
          net = 1
        end
        user.recalculate_vote_ratio
        self.votes_count -= vote.amount
        vote.destroy
      end
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, net)
      net
    end
  end

  # Include this module to get sentiment functionality for root level documents.
  # @example Add sentiment support to a document.
  #   require "limelight"
  #   class Topic
  #     include Limelight::Sentiment
  #   end
  module Sentiment
    extend ActiveSupport::Concern

    included do
      SENTIMENTS = ['positive', 'negative', 'neutral']

      field :sentiments_count, :default => {}
    end

    def add_sentiment(user_id, sentiment)
      if SENTIMENTS.include?(sentiment)
        self.sentiments_count[sentiment] ||= 0
        self.sentiments_count[sentiment] += 1
      end
    end

    def remove_sentiment(user_id, sentiment)
      if SENTIMENTS.include?(sentiment)
        self.sentiments_count[sentiment] -= 1
      end
    end
  end

  module Mentions
    extend ActiveSupport::Concern

    included do
      field :primary_topic_mention

      embeds_many :user_mentions, as: :user_mentionable
      embeds_many :topic_mentions, as: :topic_mentionable

      attr_accessible :mention1, :mention2, :mention1_id, :mention2_id, :first_response
      attr_accessor :primary_topic_pm

      before_create :set_mentions
    end

    def title_clean
      clean = ''
      if @title_raw.blank? && title
        clean = title.gsub(/[\#\@]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '\2')
      elsif !@title_raw.blank?
        # old mentions
        clean = @title_raw.gsub(/[\#\@]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '\2')
        # new mentions
        clean = clean.gsub(/[\#]\[([a-zA-Z0-9,!\-_:'&\?\$ ]*)\]/, '\2')
      end
      clean
    end

    def content_clean
      clean = ''
      if @content_raw.blank? && content
        clean = content.gsub(/[\#\@]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '\2')
      elsif !@content_raw.blank?
        # old mentions
        clean = @content_raw.gsub(/[\#\@]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '\2')
        # new mentions
        clean = clean.gsub(/[\#]\[([a-zA-Z0-9,!\-_:'&\?\$ ]*)\]/, '\2')
      end
      clean
    end

    def mentions?(id)
      !!topic_mentions.detect{|mention| mention.id == id}
    end

    def send_mention_notifications
      sent = []
      self.user_mentions.each do |mentioned_user|
        unless sent.include?(mentioned_user.id)
          target_user = User.find(mentioned_user.id)
          Notification.add(target_user, :mention, true, self.user, nil, nil, true, self, self.user)
          sent << target_user.id
        end
      end
    end

    def set_mentions
      self.primary_topic_pm = -1

      set_user_mentions
      set_topic_mentions
    end

    # Checks @content_raw for user mentions
    def set_user_mentions
      return unless content
      found_users = Array.new

      # Searches for strings following @username. Returns an array of usernames.
      content.scan(/\@([0-9a-zA-Z]*)/).each do |user|
        unless found_users.include? user[0]
          found_users << user[0].to_url
        end
      end

      # Find the users
      users = User.where(:slug.in => found_users)

      users.each do |user|
        self.user_mentions.build({id: user.id, public_id: user.public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
      end
    end

    # Checks @content_raw for topic mentions
    # Checks @ooc_mentions for out of context mentions
    def set_topic_mentions
      existing_ids = []
      new_names = []
      [[mention1, mention1_id], [mention2, mention2_id]].each do |m|
        unless m[0].blank?
          if m[1] == "0"
            new_names << m[0]
          elsif m[1].blank?
            existing = Topic.where("aliases.slug" => m[0].to_url).order_by(:score, :desc).first
            if existing
              existing_ids << existing.id
            else
              new_names << m[0]
            end
          else
            existing_ids << m[1]
          end
        end
      end
      save_topic_mentions(existing_ids)
      save_new_topic_mentions(new_names)
    end

    def save_topic_mentions(found_topics)
      # Add the found topics as snippets
      mentions = Topic.where(:_id.in => found_topics)
      mentions.each do |topic|
        save_topic_mention(topic)
      end
    end

    # takes an array of new topic names
    def save_new_topic_mentions(topic_mention_names)
      # See if any of the new topic slugs are already in the DB. Check through topic aliases! Only connect to topics without a type assigned.
      new_topic_mentions = topic_mention_names.map {|name| [name, name.to_url]}

      topic_slugs = new_topic_mentions.map {|data| data[1]}
      # topics with matching aliases that are NOT already typed
      topics = Topic.where("aliases.slug" => {'$in' => topic_slugs}, "primary_type_id" => {"$exists" => false}).to_a

      new_topic_mentions.each do |topic_mention|
        found_topic = false
        # Do we already have an *untyped* DB topic for this mention?
        topics.each do |topic|
          if topic.has_alias? topic_mention[1]
            found_topic = topic
          end
        end
        unless found_topic
          # If we did not find the topic, create it and save it if it is valid
          found_topic = user.topics.build({name: topic_mention[0]})
          if found_topic.valid?
            found_topic.save
          else
            found_topic = false
          end
        end

        save_topic_mention(found_topic) if found_topic
      end
    end

    def save_topic_mention(topic)
      existing = topic_mentions.detect{|mention| mention.id == topic.id}
      unless existing
        payload = {id: topic.id, public_id: topic.public_id, name: topic.name, slug: topic.slug }
        self.topic_mentions.build(payload)
        if topic.score > primary_topic_pm
          self.primary_topic_mention = topic.id
          self.primary_topic_pm = topic.score
        end
      end
    end

    def remove_topic_mentions_of(topic_id)
      # Loop through all of the topic mentions with the given id
      self.content.scan(/\#\[#{topic_id.to_s}#([a-zA-Z0-9,!\-_:'&\?\$ ]+)\]/).each do |topic|
        # If we found a match, replace the mention with just the text
        self.content.gsub!(/\#\[#{topic_id.to_s}##{topic[0]}\]/, topic[0])
      end

      self.topic_mentions.delete_all(conditions: {id: topic_id})
      save
    end

    def mentioned_topics
      Topic.where(:_id.in => topic_mentions.map{|t| t.id})
    end

    def mentioned_ids
      topic_mentions.map{|m| m.id}
    end

    # BETA REMOVE
    #def parse_mentions(text)
    #  # Search for regular topic mentions
    #  found_topics = Array.new
    #  # Searches for strings contained between #[uid#topic_name] delimiters. Returns an array of arrays of format [[uid,topic_name],[uid,topic_name]...].
    #  text.scan(/\#\[([0-9a-zA-Z]*)#([a-zA-Z0-9,!\-_:'&\?\$ ]*)\]/).map do |topic|
    #    unless found_topics.include? topic[0]
    #      found_topics << topic[0]
    #    end
    #  end
    #  save_topic_mentions(found_topics, false) if found_topics.length > 0
    #
    #  # Search for topic short name mentions
    #  short_names = Array.new
    #  # Searches for short names in format #ShortName
    #  text.scan(/\#([a-zA-Z0-9]*)/).map do |short_name|
    #    unless short_names.include?(short_name) || short_name[0].blank?
    #      short_names << short_name[0]
    #    end
    #  end
    #  # Add short name mentions
    #  if short_names && short_names.length > 0
    #    mentions = Topic.where(:short_name => {'$in' => short_names}).to_a
    #    mentions.each do |topic|
    #      existing = topic_mentions.detect{|mention| mention.id == topic.id}
    #      unless existing
    #        payload = {id: topic.id, public_id: topic.public_id, name: topic.name, slug: topic.slug, ooc: false, short_name: topic.short_name }
    #        self.topic_mentions.build(payload)
    #        if topic.score > primary_topic_pm
    #          self.primary_topic_mention = topic.id
    #          self.primary_topic_pm = topic.score
    #        end
    #      end
    #    end
    #  end
    #
    #  # Search for new topic mentions
    #  # Explodes the string. Returns an array of arrays containing
    #  # [string, slugified string] without duplicates.
    #  new_topic_mentions = text.scan(/\#\[([a-zA-Z0-9,!\-_:'&\?\$ ]*[^#])\]/).flatten(1).map do |topic|
    #    # strip of disallowed characters
    #    cleaned = topic.strip.chomp(',').chomp('.').chomp('!').chomp('-').chomp('_')
    #    text.gsub!(/\#\[#{topic}\]/, "#[#{cleaned}]")
    #    [cleaned, topic.to_url, false]
    #  end.uniq
    #  save_new_topic_mentions(new_topic_mentions)
    #end
  end

  module Popularity
    extend ActiveSupport::Concern

    included do
      @@pop_amounts = {
        :v_up => 1.0,
        :v_down => -1.0,
        :lk => 1.0,
        :new => 0.5,
        :fav => 0,
        :flw => 2.0,
        :share => 0.5,

        # Modifiers
        :mention => 0.5,
        :user => 0.5
      }

      field :score, :default => 0.0
    end

    def add_pop_vote(subtype, net, current_user)
      amt = nil
      if subtype == :a
        case net
          when 1
            amt = add_pop_action :v_up, :a, current_user
          when 2
            amt = add_pop_action :v_down, :r, current_user
            amt += add_pop_action :v_up, :a, current_user
          when -1
            amt = add_pop_action :v_down, :a, current_user
          when -2
            amt = add_pop_action :v_up, :r, current_user
            amt += add_pop_action :v_down, :a, current_user
        end
      elsif subtype == :r
        case net
          when 1
            amt = add_pop_action :v_down, :r, current_user
          when -1
            amt = add_pop_action :v_up, :r, current_user
        end
      end
      amt
    end

    # secondary boolean means the function is being called on the parent of the object which actually had the action
    def add_pop_action(type, subtype, current_user, secondary=false)
      amt = 0
      if subtype == :a
        amt = @@pop_amounts[type]
      elsif subtype == :r
        amt = @@pop_amounts[type] * -1
      end

      amt = amt * current_user.clout
      if defined? topic_mentions
        amt = 2 * amt / topic_mentions.length if topic_mentions.length > 2
      end
      amt = amt / 10 if secondary

      if amt != 0
        action = current_user.popularity_actions.new(:type => type, :subtype => subtype, :object_id => id)
        snippet_attrs = {:amount => amt, :id => id, :object_type => self.class.name}

        if ["User", "Topic"].include? self.class.name
          action.pop_snippets.new(snippet_attrs)
        else
          snippet_attrs[:root_id] = root_id if root_id
          snippet_attrs[:root_type] = root_type if root_id
          action.pop_snippets.new(snippet_attrs)

          # Update user if not a link, video, or picture and this is not a :new action
          unless type == :new || ["Link", "Video", "Picture"].include?(self.class.name)
            user_amt = amt * @@pop_amounts[:user]

            action.pop_snippets.new(:amount => user_amt, :id => user_id, :object_type => "User")
            User.collection.update(
              {:_id => user_id},
              {
                "$inc" => { :score => user_amt }
              }
            )
            Pusher[user_id.to_s].trigger('popularity_changed', {:id => user_id.to_s, :change => user_amt})
            User.expire_caches(user_id.to_s)
          end

          # Update mentioned topics if applicable
          if defined? topic_mentions
            mention_amt = amt * @@pop_amounts[:mention]

            topic_mentions.each do |t_mention|
              action.pop_snippets.new(:amount => mention_amt, :id => t_mention.id, :object_type => "Topic")
              Pusher[t_mention.id.to_s].trigger('popularity_changed', {:id => id.to_s, :change => mention_amt})
            end

            # Update the popularities on affected objects
            Topic.collection.update(
              {:_id => {"$in" => ooc_ids}},
              {
                "$inc" => { :score => ooc_amt }
              }
            )
            ooc_ids.each {|target| Topic.expire_caches(target.to_s)}
            Topic.collection.update(
              {:_id => {"$in" => ic_ids}},
              {
                "$inc" => { :score => ic_amt }
              }
            )
            ic_ids.each {|target| Topic.expire_caches(target.to_s)}
          end

          # Removed because popularity for push feeds is aggregated around the root
          #if response_to
          #  object = Post.find(response_to.id)
          #  object.add_pop_action(type, subtype, current_user, true) if object
          #end
        end

        action.save!
        change_pop(amt)

        amt
      end
    end

    protected

    def change_pop(amt)
      self.score += amt
    end
  end
end
