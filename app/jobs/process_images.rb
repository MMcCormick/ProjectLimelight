class ProcessImages

  @queue = :fast

  def self.perform(target_id, target_model, version)
    target = Kernel.const_get(target_model).find(target_id)
    if target
      target.process_version(version)
      target.processing_image = false
      target.save
    end
  end
end