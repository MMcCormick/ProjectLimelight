class AddPopAction

  @queue = :medium_limelight

  def self.perform(post_id, type, subtype, user_id, amt)
    post = Post.find(post_id)
    user = User.find(user_id)

    post.add_pop_action_helper(type.to_sym, subtype.to_sym, user, amt.to_i)
  end
end