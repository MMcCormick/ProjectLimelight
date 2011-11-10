class RecalculateClout
  include Resque::Plugins::UniqueJob

  @queue = :popularity

  def self.perform
    users = User.all.asc(:pt)
    num_users = User.count

    users.each_with_index do |user, i|
      user.clout = 2.5 * (i+1) / num_users + 0.5
      user.save!
    end
  end
end