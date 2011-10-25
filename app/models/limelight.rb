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
      if image
        original = image.original.first.image.file
        new_image = Image.from_blob(original.read).first

        case style
          when 'square'
            new_image = new_image.resize_to_fill(dimensions[0], dimensions[1])
          else
            new_image = new_image.resize_to_fit(dimensions[0], dimensions[1])
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
      if valid? && @asset_image
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
      if !vote
        self.votes.create(:_id => user.id, :amount => amount)
        self.votes_count += amount
        if amount > 0
          user.vote_pos_count += 1
        else
          user.vote_neg_count += 1
        end
      elsif vote.amount != amount
        self.votes_count = votes_count - vote.amount + amount
        vote.amount = amount
        if amount > 0
          user.vote_pos_count += 1
          user.vote_neg_count -= 1
        else
          user.vote_pos_count -= 1
          user.vote_neg_count += 1
        end
      end
      user.recalculate_vote_ratio
    end

    def remove_voter(user)
      vote = voter? user.id
      if vote
        if vote.amount > 0
          user.vote_pos_count -= 1
        else
          user.vote_neg_count -= 1
        end
        user.recalculate_vote_ratio
        self.votes_count -= vote.amount
        vote.destroy
      end
    end
  end

  module Mentions
    extend ActiveSupport::Concern

    included do
      embeds_many :user_mentions, as: :user_mentionable
      embeds_many :topic_mentions, as: :topic_mentionable

      before_create :set_mentions

      attr_accessible :content_raw
      attr_accessor :content_raw
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

    # TODO: deal with punctuation
    # Checks @content_raw for topic mentions
    def set_topic_mentions
      return unless @content_raw
      if @content_raw
        found_topics = Array.new
        # Searches for strings contained between #[uid#topic_name] delimiters. Returns an array of arrays of format [[uid,topic_name],[uid,topic_name]...].
        @content_raw.scan(/\#\[([0-9a-zA-Z]*)#([a-zA-Z0-9,!\-_ ]*)\]/).map do |topic|
          unless found_topics.include? topic[0]
            found_topics << topic[0]
          end
        end

        # Add the found topics as snippets
        mentions = Topic.where(:_id.in => found_topics)
        mentions.each do |topic|
          payload = {id: topic.id, public_id: topic.public_id, name: topic.name, slug: topic.slug }
          self.topic_mentions.build(payload)
        end

        # Explodes the string. Returns an array of arrays containting
        # [string, slugified string] without duplicates.
        new_topic_mentions = @content_raw.scan(/\#\[([a-zA-Z0-9,!\-_  ]*[^#])\]/).flatten(1).map do |topic|
          cleaned = topic.strip.chomp(',').chomp('.').chomp('!').chomp('-').chomp('_')
          @content_raw.gsub!(/\#\[#{topic}\]/, "#[#{cleaned}]")
          [cleaned, topic.to_url]
        end.uniq

        # See if any of the topic slugs are already in the DB. Check through topic aliases!
        topic_slugs = topic_mentions.map { |data| data[1] }
        topics = Topic.where("aliases" => { '$in' => topic_slugs})

        new_topic_mentions.each do |topic_mention|
          found_topic = false
          # Do we already have a DB topic for this mention?
          topics.each do |topic|
            if topic.slug == topic_mention[1]
              found_topic = topic
            end
          end
          # If we did not find the topic, create it and save it if it is valid
          if found_topic == false
            found_topic = user.topics.build({name: topic_mention[0]})
            if found_topic.valid?
              found_topic.save
              # add the new ID to the topic mention
              @content_raw.gsub!(/\#\[#{topic_mention[0]}\]/, "#[#{found_topic.id.to_s}##{topic_mention[0]}]")
            else
              found_topic = false
            end
          end
          if found_topic
            payload = {id: found_topic.id, public_id: found_topic.public_id, name: found_topic.name, slug: found_topic.slug }
            self.topic_mentions.build(payload)
          end
        end
      end
    end
  end

end
