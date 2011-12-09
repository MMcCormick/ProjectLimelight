require 'RMagick'
include Magick

# Embeddable image snippet that holds useful (denormalized) image info
class ImageSnippet

  include Mongoid::Document

  field :status, :default => 'active'
  field :isDefault, :default => true
  field :user_id
  embeds_many :versions, :class_name => 'AssetImage'

  embedded_in :image_assignable, polymorphic: true

  def add_uploaded_version(params, isOriginal=false)
    params.merge!( {:isOriginal => isOriginal} )
    version = AssetImage.new(params)
    version.id = id
    if !params[:remote_image_url].blank?
      version.save_image(params[:remote_image_url])
    elsif !params[:image_cache].blank?
      version.save_image(params[:image_cache])
    end
    self.versions << version
  end

  def find_version dimensions, mode
    versions.where(:resizedTo => "#{dimensions[0]}x#{dimensions[1]}", :mode => mode).first
  end

  def original
    versions.each do |version|
      version if version.isOriginal
    end
  end

end