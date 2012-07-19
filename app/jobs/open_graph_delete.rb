class OpenGraphDelete
  include Resque::Plugins::UniqueJob
  @queue = :medium

  def self.perform(user_id, target_id, target_type, action)
    user = User.find_by_slug_id(user_id)
    target = Kernel.const_get(target_type).find_by_slug_id(target_id)
    if user && target
      fb = user.facebook
      if fb
        case action
          when 'follow' && user.og_follows
            ll_action = ActionFollow.where(:fid => user.id, :tid => target.id, :a => 'create').desc(:_id).first
          else
            ll_action = nil
        end

        if ll_action && ll_action.og_id
          fb.delete_object(ll_action.og_id)
        end
      end
    end
  end
end