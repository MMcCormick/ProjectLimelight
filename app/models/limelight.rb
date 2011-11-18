require 'RMagick'
include Magick

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
    #   document.has_permission?
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
      self.grant_permission(object_id, "edit")
      self.grant_permission(object_id, "delete")
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

    def add_image_version(image_id, dimensions, style)
      image = self.images.find(image_id)

      if image && image.original
        original = image.original.first.image.file
        new_image = Image.from_blob(original.read).first

        width = dimensions[0] == 0 ? 999999 : dimensions[0]
        height = dimensions[1] == 0 ? 999999 : dimensions[1]

        case style
          when 'square'
            new_image = new_image.resize_to_fill(width, height)
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
        version = AssetImage.new(:isOriginal => false, :resizedTo => "#{dimensions[0]}x#{dimensions[1]}", :style => style, :width => new_image.columns, :height => new_image.rows)
        version.id = image.id
        version.image.store!(File.open(tmp_location))
        image.versions << version
        version.save
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
        # Create/attach the news image
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
      net
    end
  end

  module Mentions
    extend ActiveSupport::Concern

    included do
      embeds_many :user_mentions, as: :user_mentionable
      embeds_many :topic_mentions, as: :topic_mentionable

      before_create :set_mentions

      attr_accessible :content_raw, :ooc_mentions
      attr_accessor :content_raw, :ooc_mentions
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
      set_user_mentions
      set_topic_mentions
      self.content = @content_raw
    end

    # Checks @content_raw for user mentions
    def set_user_mentions
      return unless @content_raw
      found_users = Array.new
      # Searches for strings contained between @[uid#username] delimiters. Returns an array of arrays of format [[uid,username],[uid,username]...].
      @content_raw.scan(/\@\[([0-9a-zA-Z]*)#([\w]*)\]/).map do |user|
        unless found_users.include? user[0]
          found_users << user[0]
        end
      end

      # Find the users
      users = User.where(:_id.in => found_users)

      users.each do |user|
        self.user_mentions.build({id: user.id, public_id: user.public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
      end
    end

    # Checks @content_raw for topic mentions
    # Checks @ooc_mentions for out of context mentions
    def set_topic_mentions
      return unless @content_raw || @ooc_mentions

      if @content_raw
        found_topics = Array.new
        # Searches for strings contained between #[uid#topic_name] delimiters. Returns an array of arrays of format [[uid,topic_name],[uid,topic_name]...].
        @content_raw.scan(/\#\[([0-9a-zA-Z]*)#([a-zA-Z0-9,!\-_:' ]*)\]/).map do |topic|
          unless found_topics.include? topic[0]
            found_topics << topic[0]
          end
        end

        save_topic_mentions(found_topics, false) if found_topics.length > 0

        # Explodes the string. Returns an array of arrays containing
        # [string, slugified string] without duplicates.
        new_topic_mentions = @content_raw.scan(/\#\[([a-zA-Z0-9,!\-_:' ]*[^#])\]/).flatten(1).map do |topic|
          # strip of disallowed characters
          cleaned = topic.strip.chomp(',').chomp('.').chomp('!').chomp('-').chomp('_')
          @content_raw.gsub!(/\#\[#{topic}\]/, "#[#{cleaned}]")
          [cleaned, topic.to_url, false]
        end.uniq

        save_new_topic_mentions(new_topic_mentions)
      end

      @ooc_mentions = Yajl::Parser.parse(@ooc_mentions) if @ooc_mentions
      if @ooc_mentions
        save_topic_mentions(@ooc_mentions['existing'], true) if @ooc_mentions['existing'].length > 0

        if @ooc_mentions['new'].length > 0
          new_mentions = @ooc_mentions['new'].map do |topic|
            cleaned = topic.strip.chomp(',').chomp('.').chomp('!').chomp('-').chomp('_')
            [cleaned, topic.to_url, true]
          end

          save_new_topic_mentions(new_mentions)
        end
      end
    end

    def save_topic_mentions(found_topics, ooc=false)
      # Add the found topics as snippets
      mentions = Topic.where(:_id.in => found_topics)
      mentions.each do |topic|
        existing = topic_mentions.detect{|mention| mention.id == topic.id}
        unless existing
          payload = {id: topic.id, public_id: topic.public_id, name: topic.name, slug: topic.slug }
          self.topic_mentions.build(payload.merge!(:ooc => ooc))
        end
      end
    end

    def save_new_topic_mentions(new_topic_mentions)
      # See if any of the new topic slugs are already in the DB. Check through topic aliases! Only connect to topics without a type assigned.
      topic_slugs = new_topic_mentions.map {|data| data[1]}
      topic_slugs.uniq!
      topics = Topic.where("aliases" => { '$in' => topic_slugs}).to_a
      #TODO: need new version of logic for topic_type_snippets? see below vs above
      #topics = Topic.where("aliases" => { '$in' => topic_slugs}, "topic_type_snippets" => {"$exists" => false}).to_a

      new_topic_mentions.each do |topic_mention|
        found_topic = false
        # Do we already have a DB topic for this mention?
        topics.each do |topic|
          if topic.has_alias? topic_mention[1]
            found_topic = topic
          end
        end
        # If we did not find the topic, create it and save it if it is valid
        if found_topic == false
          found_topic = user.topics.build({name: topic_mention[0]})
          if found_topic.valid?
            found_topic.save
          else
            found_topic = false
          end
        end
        if found_topic
          # add the new ID to the topic mention
          @content_raw.gsub!(/\#\[#{topic_mention[0]}\]/, "#[#{found_topic.id.to_s}##{topic_mention[0]}]")

          payload = {id: found_topic.id, public_id: found_topic.public_id, name: found_topic.name, slug: found_topic.slug, :ooc => topic_mention[2]}
          self.topic_mentions.build(payload)
        end
      end
    end
  end

  module Popularity
    extend ActiveSupport::Concern

    included do
      pop_amounts = {
        :v_up => 1.0,
        :v_down => -1.0,
        :rp => 3.0,
        :fav => 2.0,
        :flw => 10.0,
        :share => 1,

        # Modifiers
        :ooc => 0.3,
        :ic => 0.5,
        :user => 0.5
      }

      field :ph, :default => 0.0
      field :pd, :default => 0.0
      field :pw, :default => 0.0
      field :pm, :default => 0.0
      field :pt, :default => 0.0

      field :phc, :default => false
      field :pdc, :default => false
      field :pwc, :default => false
      field :pmc, :default => false
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

    def add_pop_action(type, subtype, current_user)
      amt = 0
      if subtype == :a
        amt = POP_AMOUNTS[type]
      elsif subtype == :r
        amt = POP_AMOUNTS[type] * -1
      end

      amt = amt * current_user.clout
      unless ["User", "Topic"].include? self.class.name
        amt = 2 * amt / topic_mentions.length if topic_mentions.length > 2
      end

      if amt != 0
        action = current_user.popularity_actions.new(:type => type, :subtype => subtype, :object_id => id)
        action.pop_snippets.new(:amount => amt, :id => id, :object_type => self.class.name)

        unless ["User", "Topic"].include? self.class.name

          ooc_amt = amt * POP_AMOUNTS[:ooc]
          ic_amt = amt * POP_AMOUNTS[:ic]
          user_amt = amt * POP_AMOUNTS[:user]

          ooc_ids, ic_ids = [], []

          topic_mentions.each do |t_mention|
            if t_mention.ooc
              ooc_ids << t_mention.id
              action.pop_snippets.new(:amount => ooc_amt, :id => t_mention.id, :object_type => "Topic")
              Pusher[t_mention.id.to_s].trigger('popularity_changed', {:change => ooc_amt})
            else
              ic_ids << t_mention.id
              action.pop_snippets.new(:amount => ic_amt, :id => t_mention.id, :object_type => "Topic")
              Pusher[t_mention.id.to_s].trigger('popularity_changed', {:change => ic_amt})
            end
          end
          action.pop_snippets.new(:amount => user_amt, :id => user_id, :object_type => "User")

          # Update the popularities on affected objects
          Topic.collection.update(
            {:_id => {"$in" => ooc_ids}},
            {
              "$inc" => { :ph => ooc_amt, :pd => ooc_amt, :pw => ooc_amt, :pm => ooc_amt, :pt => ooc_amt },
              "$set" => { :phc => true, :pdc => true, :pwc => true, :pmc => true }
            }
          )
          Topic.collection.update(
            {:_id => {"$in" => ic_ids}},
            {
              "$inc" => { :ph => ic_amt, :pd => ic_amt, :pw => ic_amt, :pm => ic_amt, :pt => ic_amt },
              "$set" => { :phc => true, :pdc => true, :pwc => true, :pmc => true }
            }
          )
          User.collection.update(
            {:_id => user_id},
            {
              "$inc" => { :ph => user_amt, :pd => user_amt, :pw => user_amt, :pm => user_amt, :pt => user_amt },
              "$set" => { :phc => true, :pdc => true, :pwc => true, :pmc => true }
            }
          )
          Pusher[user_id.to_s].trigger('popularity_changed', {:change => user_amt})
        end

        action.save!
        change_pop(amt)
        amt
      end
    end

    protected

    def change_pop(amt)
      self.ph += amt
      self.pd += amt
      self.pw += amt
      self.pm += amt
      self.pt += amt

      self.phc = true
      self.pdc = true
      self.pwc = true
      self.pmc = true
      Pusher[id.to_s].trigger('popularity_changed', {:change => amt})
    end
  end
end
