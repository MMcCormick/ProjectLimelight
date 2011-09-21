class ImageProcessor
  @queue = :images_queue
  def self.perform(target_model, target_id, image_id, dimensions)
    target = Kernel.const_get(target_model).find(target_id)
    target.add_image_version image_id, dimensions
    target.save
  end
end