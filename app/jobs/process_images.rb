class ProcessImages

  @queue = :one

  def self.perform(target_id, target_model, version, set_active=false)
    target = Kernel.const_get(target_model).find(target_id)
    if target
      target.process_version(version)
      if set_active
        target.make_image_version_current(version)
      end
      target.processing_image = false
      target.save
    end
  end
end