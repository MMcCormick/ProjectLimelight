class ImageProcessor
  include Resque::Plugins::UniqueJob

  @queue = :images

  def self.perform(target_model, target_id, image_id, dimensions, mode)
    target = Kernel.const_get(target_model).find(target_id)
    target.add_image_version image_id, dimensions, mode
    target.save
  end
end