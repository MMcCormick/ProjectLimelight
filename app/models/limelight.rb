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
    def has_permission?(object_id, permission)
      self.permissions[permission] && self.permissions[permission].include?(object_id)
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
    end

    def save_images
      self.images.each do |image|
        image.versions.each do |version|
          version.save
        end
      end
    end

    # @example Return the url to the current default image

    # @return AssetImage
    def default_image
      self.images.each do |image|
        image if image.isDefault?
      end
    end

    def add_image_version(image_id, dimensions)
      image = self.images.find(image_id)
      if image
        original = image.original.first.image.file
        new_image = Image.from_blob(original.read).first
        new_image = new_image.resize_to_fit(dimensions[0], dimensions[1])
        tmp_location = "/tmp/d#{dimensions[0]}x#{dimensions[1]}_#{original.filename}"
        new_image.write tmp_location
        version = AssetImage.new(:isOriginal => false, :resizedTo => "#{dimensions[0]}x#{dimensions[1]}", :width => new_image.columns, :height => new_image.rows)
        version.id = image.id
        version.image.store!(File.open(tmp_location))
        image.versions << version
        version.save
      end
    end
  end
end