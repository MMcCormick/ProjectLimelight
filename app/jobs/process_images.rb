class ProcessImages

  @queue = :fast

  def self.perform(target_id, target_model, version=nil)
    target = Kernel.const_get(target_model).find(target_id)
    if target
      if target.active_image_version == 0 && target.remote_image_url
        target.save_remote_image(true)
        target.save
      elsif version
        target.process_version(version)
        target.processing_image = false
        target.save
      end
    end
  end
end