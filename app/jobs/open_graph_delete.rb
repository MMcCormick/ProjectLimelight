class OpenGraphDelete
  include Resque::Plugins::UniqueJob
  @queue = :medium

  def self.perform(user_id, target_id, target_type, action)
    user = User.find(user_id)
    target = Kernel.const_get(target_type).find(target_id)
    if user && target
      fb = user.facebook
      if fb
        case action
          when 'follow'
            ll_action = ActionFollow.where(:fid => user.id, :tid => target.id, :a => 'create').order_by(:created_at, :desc).first
          when 'like'
            ll_action = ActionLike.where(:fid => user.id, :tid => target.id, :a => 'create').order_by(:created_at, :desc).first
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