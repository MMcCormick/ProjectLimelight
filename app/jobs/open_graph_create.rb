class OpenGraphCreate
  include Resque::Plugins::UniqueJob
  include ModelUtilitiesHelper
  @queue = :medium_limelight

  def initialize(user, target, action, object_type, object_url, fb)
    return if Rails.env.development?

    og_id = fb.put_connections("me", "#{og_namespace}:#{action}", object_type.to_sym => object_url)
    if og_id && og_id['id']
      case action
        when 'follow' && user.og_follows
          ll_action = ActionFollow.where(:fid => user.id, :tid => target.id, :a => 'create').desc(:_id).first
        else
          ll_action = nil
      end

      if ll_action
        ll_action.og_id = og_id['id']
        ll_action.save
      end

    end
  end

  def self.perform(user_id, target_id, target_type, action, object_type, object_url)
    return if Rails.env.development?

    user = User.find(user_id)
    target = Kernel.const_get(target_type).find_by_slug_id(target_id)
    if user && target
      fb = user.facebook
      if fb
        new(user, target, action, object_type, object_url, fb)
      end
    end
  end
end