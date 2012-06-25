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
      field :image_versions, :default => 0
      field :active_image_version, :default => 0
      field :processing_image, :default => false
      field :remote_image_url

      attr_accessible :remote_image_url
    end

    def size_dimensions
      {:small => 50, :normal => 100, :large => 300}
    end

    def available_sizes
      [:small, :normal, :large]
    end

    def available_modes
      [:square, :fit]
    end

    def filepath
      if self.class.name == 'User'
        path = 'users'
      elsif self.class.name == 'Topic'
        path = 'topics'
      else
        path = self.class.name.downcase.pluralize
      end

      "#{path}/#{id.to_s}"
    end

    def current_filepath
      "#{filepath}/#{active_image_version}"
    end

    def image_url(mode, size=nil, version=nil, original=false)
      version = active_image_version unless version
      if self.class.name == 'User' && use_fb_image
        if mode == :square
          "http://graph.facebook.com/#{fbuid}/picture?type=square"
        else
          "http://graph.facebook.com/#{fbuid}/picture?type=#{size}"
        end
      else
        if version == 0
          if self.class.name == 'User'
            "http://www.gravatar.com/avatar?d=mm&f=y&s=#{size_dimensions[size]}"
          elsif self.class.name == 'Topic'
            if use_freebase_image
              "https://usercontent.googleapis.com/freebase/v1/image#{freebase_id}?maxheight=#{size_dimensions[size]}&maxwidth=#{size_dimensions[size]}&mode=#{mode == :fit ? 'fit' : 'fillcropmid'}&pad=true"
            else
              "#{S3['image_prefix']}/defaults/topics/#{size}.gif"
            end
          elsif !remote_image_url.blank?
            "#{remote_image_url}"
          end
        else
          if processing_image
            "#{S3['image_prefix']}/#{filepath}/#{version.to_i}/original.png"
          else
            if original
              "#{S3['image_prefix']}/#{filepath}/#{version.to_i}/original.png"
            else
              "#{S3['image_prefix']}/#{filepath}/#{version.to_i}/#{mode}_#{size}.png"
            end
          end
        end
      end
    end

    # Saves a new set of images from the remote_image_url currently specified on the model
    def save_remote_image(force=false)
      unless remote_image_url.blank?
        target = "#{filepath}/#{active_image_version.to_i+1}/original.png"

        begin
          AWS::S3::S3Object.store(
            target,
            open(remote_image_url).read,
            S3['image_bucket']
          )
        rescue => e
          return
        end

        AWS::S3::S3Object.copy target, "#{current_filepath}/original.png", S3['image_bucket']

        self.image_versions += 1
        self.active_image_version = image_versions
        self.processing_image = true

        if force
          process_version(active_image_version)
          self.processing_image = false
        end
      end
    end

    def process_images
      if processing_image || (!remote_image_url.blank? && active_image_version == 0)
        Resque.enqueue(ProcessImages, id.to_s, self.class.name, remote_image_url)
      end
    end

    def process_version(version)
      i = Magick::Image::read("#{S3['image_prefix']}/#{filepath}/#{version}/original.png").first
      if i
        original_w = i.columns
        original_h = i.rows

        # Generate all the image versions we need
        available_sizes.each do |size|
          available_modes.each do |mode|
            # is it already on S3?
            unless AWS::S3::S3Object.exists? "#{filepath}/#{version}/#{mode}_#{size}.png", S3['image_bucket']
              dimensions = size_dimensions
              width = dimensions[size]
              height = mode == :fit ? 999999 : dimensions[size]

              # we don't resize larger than the original image. if the original is smaller, use that max size and mantain the ratio
              if original_w < width
                width = original_w
                unless mode == :fit
                  height = original_h
                end
              end

              case mode
                when :square
                  new_image = i.resize_to_fill(width, height)
                when :fit
                  new_image = i.resize_to_fit(width, height)
                else
                  new_image = nil
              end

              # upload to s3
              if new_image
                target = "#{filepath}/#{version}/#{mode}_#{size}.png"
                AWS::S3::S3Object.store(
                  target,
                  new_image.to_blob,
                  S3['image_bucket'],
                  :access => :public_read
                )
              end
            end
          end
        end
        true
      else
        nil
      end
    end
  end

  module Mentions
    extend ActiveSupport::Concern

    included do
      embeds_many :pre_mentions, as: :topic_mentionable, :class_name => "TopicMention"

      has_and_belongs_to_many :topic_mentions, :inverse_of => nil, :class_name => 'Topic'
      has_and_belongs_to_many :user_mentions, :inverse_of => nil, :class_name => 'User'

      attr_accessor :topic_mention_names, :first_response, :primary_topic_pm
      attr_accessible :topic_mention_ids, :user_mention_ids, :topic_mention_names, :first_response

      before_validation :set_mentions
      validates :topic_mention_ids, :length => { :minimum => 1, :maximum => 2, :message => 'You must add 1-2 topics to your post.' }
    end

    def mentions_topic?(id)
      topic_mention_ids.include?(id)
    end

    #
    # SETTING MENTIONS
    #

    def set_mentions
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
          found_users << user[0].parameterize
        end
      end

      # Find the users
      self.user_mentions = User.where(:slug.in => found_users)
    end

    def set_topic_mentions
      save_new_topic_mentions(topic_mention_names) if topic_mention_names && topic_mention_names.length > 0
    end

    # takes an array of new topic names
    def save_new_topic_mentions(topic_mention_names)
      # See if any of the new topic slugs are already in the DB. Check through topic aliases! Only connect to topics without a type assigned.
      new_topic_mentions = topic_mention_names.map {|name| [name, name.parameterize]}

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

        self.topic_mentions << found_topic if found_topic
      end
    end

    def bubble_up
      #if post_media_id
      #  topic_mentions.each do |topic|
      #    post_media.suggest_mention(topic)
      #  end
      #  post_media.save
      #end
    end

    def suggest_mention(topic)
      #unless topic_mention_ids.include?(topic.id)
      #  root_pre_mention = pre_mentions.find(topic.id)
      #  if root_pre_mention
      #    root_pre_mention.score += 1
      #    if root_pre_mention.score >= TopicMention.threshold
      #      add_topic_mention(topic)
      #    end
      #  else
      #    pre_m = self.pre_mentions.build(topic.attributes)
      #    pre_m.id = topic.id
      #  end
      #end
    end

    def add_topic_mention(topic)
      unless topic_mention_ids.include?(topic.id)
        self.topic_mentions << topic
        #pre_mention = pre_mentions.find(topic.id)
        #pre_mention.destroy if pre_mention
        Resque.enqueue(PostAddTopic, self.id.to_s, topic.id.to_s)
        Neo4j.post_add_topic_mention(self, topic)
      end
    end

    def remove_topic_mention(topic)
      mention = self.topic_mention_ids.delete(topic.id)
      if mention
        Resque.enqueue(PostRemoveTopic, self.id.to_s, topic.id.to_s)
        Neo4j.post_remove_topic_mention(self, topic)
      end
    end
  end

  module Popularity
    extend ActiveSupport::Concern

    included do
      field :score, :default => 0.0
    end

    def add_pop_vote(subtype, net, current_user)
      amt = nil
      if subtype == :a
        case net
          when 1
            amt = add_pop_action :v_up, :a, current_user, 1.0
          when 2
            amt = add_pop_action :v_down, :r, current_user, -1.0
            amt += add_pop_action :v_up, :a, current_user, 1.0
          when -1
            amt = add_pop_action :v_down, :a, current_user, -1.0
          when -2
            amt = add_pop_action :v_up, :r, current_user, 1.0
            amt += add_pop_action :v_down, :a, current_user, -1.0
        end
      elsif subtype == :r
        case net
          when 1
            amt = add_pop_action :v_down, :r, current_user, -1.0
          when -1
            amt = add_pop_action :v_up, :r, current_user, 1.0
        end
      end
      amt
    end

    def add_pop_action(type, subtype, current_user, amount=nil)
      amt = if amount then amount elsif subtype == :a then 1 else -1 end
      amt = amt * current_user.clout

      if defined?(topic_mentions) && !topic_mentions.empty?
        sum = 0
        topic_mentions.each { |t| sum += t.user_percentile(current_user.id) ? t.user_percentile(current_user.id) : 0 }
        if type == :new
          amt += amt > 1 ? (sum / (8 * topic_mentions.length)) : -(sum / (8 * topic_mentions.length))
        else
          amt += amt > 1 ? (sum / (30 * topic_mentions.length)) : -(sum / (30 * topic_mentions.length))
        end
      end

      change_pop(amt) unless type == :new
      #Resque.enqueue(AddPopAction, id.to_s, type, subtype, current_user.id.to_s, amt)
      #TODO: queueing this up in resque causes the pusher part not to work... (I think, maybe not, test later)
      add_pop_action_helper(type, subtype, current_user, amt)
      amt
    end

    def add_pop_action_helper(type, subtype, current_user, amt)

      if amt != 0
        action = current_user.popularity_actions.new(:type => type, :subtype => subtype, :object_id => id)
        snippet_attrs = {:amount => amt, :id => id, :object_type => self.class.name}

        snippet_attrs[:root_id] = root_id if root_id
        snippet_attrs[:root_type] = root_type if root_id
        action.pop_snippets.new(snippet_attrs)

        if type == :new
          action.pop_snippets.new(:amount => 0, :id => user_id, :object_type => "User")
        # Update user if not a link, video, or picture and this is not a :new action
        elsif !["Link", "Video", "Picture"].include?(self.class.name)
          action.pop_snippets.new(:amount => amt, :id => user_id, :object_type => "User")
          user.score += amt # the post's user (creator)
          user.save
          Resque.enqueue_in(10.minutes, ScoreUpdate, 'User', user_id.to_s)
          Pusher[user_id.to_s].trigger('score_change', {:id => user_id.to_s, :change => amt})
        end

        # Update mentioned topics if applicable
        if topic_mention_ids.length > 0
          topic_amt = type == :new ? 1 : amt
          affected_topic_ids = []
          affected_influence_ids = []

          topic_mentions.each do |topic|
            if type != :new || (type == :new && !topic.talking_ids.include?(user_id))
              affected_topic_ids << topic.id

              action.pop_snippets.new(:amount => topic_amt, :id => topic.id, :object_type => "Topic")
              Pusher[topic.id.to_s].trigger('score_change', {:id => id.to_s, :change => topic_amt})

              if topic.score >= 0 && topic.influencers.length >= 3
                Resque.enqueue_in(10.minutes, RecalculateInfluence, topic.id.to_s)
              end

              # send the influence increase
              affected_influence_ids << topic.id

              increase = InfluenceIncrease.new
              increase.amount = topic_amt
              increase.topic_id = topic.id
              increase.object_type = 'Talk'
              increase.action = type
              increase.topic = topic
              increase.id = topic.name

              Pusher[user_id.to_s].trigger('influence_change', increase.to_json(:properties => :public))
            end
          end

          # Update the popularities on affected objects
          unless affected_topic_ids.empty?
            Topic.collection.find({:_id => {"$in" => affected_topic_ids}}).
                  update_all({
                    "$inc" => {
                      :score => topic_amt,
                      :response_count => 1
                    },
                    "$push" => {
                      :talking_ids => user_id
                    }
                  })
            affected_topic_ids.each do |tid|
              Resque.enqueue_in(10.minutes, ScoreUpdate, 'Topic', tid.to_s)
            end
          end

          unless affected_influence_ids.empty?
            Topic.collection.find({:_id => {"$in" => affected_topic_ids}}).
              update_all({
                "$inc" => {
                  "influencers."+user_id.to_s+".influence" => topic_amt
                }
              })
          end
        end

        action.save!
      end
    end

    protected

    def change_pop(amt)
      self.score += amt
      Resque.enqueue_in(10.minutes, ScoreUpdate, 'Post', id.to_s)
      Pusher[id.to_s].trigger('score_change', {:id => id.to_s, :change => amt})
    end
  end

  # Include this module to get Throttling functionality for models.
  # @example Add ACL support to a document.
  #   require "limelight"
  #   class Person
  #     include Limelight::Throttle
  #   end
  module Throttle
    extend ActiveSupport::Concern

    included do
      validate :throttle_check
    end

    def throttle_check
      #unless persisted? || user_id.to_s == User.limelight_user_id
      #  last = Kernel.const_get(self.class.name).where(:user_id => user_id).desc(:_id).limit(1).first
      #  if last && Time.now - last.created_at < 15
      #    errors.add(:limited, "You must wait at least 10 sections before posting another #{self.class.name}")
      #  end
      #end
    end
  end
end
