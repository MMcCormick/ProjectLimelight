class OpenGraphCreate
  include Resque::Plugins::UniqueJob
  include ModelUtilitiesHelper
  @queue = :medium

  def initialize(user, target, action, object_type, object_url, fb)
    og_id = fb.put_connections("me", "#{og_namespace}:#{action}", object_type.to_sym => object_url)
    if og_id && og_id['id']
      case action
        when 'follow'
          ll_action = ActionFollow.where(:fid => user.id, :tid => target.id, :a => 'create').desc(:_id).first
        when 'like'
          ll_action = ActionLike.where(:fid => user.id, :tid => target.id, :a => 'create').desc(:_id).first
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
    user = User.find(user_id)
    target = Kernel.const_get(target_type).find(target_id)
    if user && target
      fb = user.facebook
      if fb
        new(user, target, action, object_type, object_url, fb)
      end
    end
  end
end