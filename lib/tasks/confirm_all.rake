desc "Confirm all existing users"
task :confirm_all => :environment do
  # get users who have not been confirmed
  users = User.where(:conrimed_at => { "$exists" => false })

  users.each do |user|
    user.confirmed_at = user.created_at
    user.save
  end
end