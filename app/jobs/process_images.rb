class ProcessImages

  @queue = :fast

  def self.perform(target_id, target_model, version, remote_image_url=nil)
    target = Kernel.const_get(target_model).find(target_id)
    if target
      if remote_image_url
        target.save_remote_image(remote_image_url, true)
        target.save
      elsif version
        target.process_version(version)
        target.processing_image = false
        target.save
      end
    end
  end
end