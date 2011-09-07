# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support:
  #include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  #include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  def scale(width, height)
    resize_to_fit(width, height)
  end

  # Create different versions of your uploaded files:
  #version :d20_20 do
  #   process :scale => [20, 20]
  #end
  #version :d30_30 do
  #   process :scale => [30, 30]
  #end
  #version :d40_40 do
  #   process :scale => [30, 30]
  #end
  #version :d50_50 do
  #   process :scale => [40, 40]
  #end
  #version :d50_50 do
  #   process :scale => [50, 50]
  #end
  #version :d60_60 do
  #   process :scale => [60, 60]
  #end
  #version :d75_75 do
  #   process :scale => [75, 75]
  #end
  #version :d100_100 do
  #   process :scale => [100, 100]
  #end
  #version :d125_125 do
  #   process :scale => [125, 125]
  #end
  #version :d150_150 do
  #   process :scale => [150, 150]
  #end
  #version :d200_200 do
  #   process :scale => [200, 200]
  #end
  #version :d250_250 do
  #   process :scale => [250, 250]
  #end
  #version :d300_300 do
  #   process :scale => [300, 300]
  #end
  #version :d500_500 do
  #   process :scale => [500, 500]
  #end
  #version :d750_750 do
  #   process :scale => [750, 750]
  #end
  #version :d1000_1000 do
  #   process :scale => [1000, 1000]
  #end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
     %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
     @name ||= "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end

end
