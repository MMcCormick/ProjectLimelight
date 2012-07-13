require 'csv'

namespace :emails do

  desc "Export the emails of users, "
  task :export => :environment do
    CSV.open("emails.csv", "w") do |csv|
      csv << ["Email", "First Name", "Last Name"]
      users = User.all
      user_emails = []
      users.each do |user|
        csv << [user.email, user.first_name, user.last_name]
        user_emails << user.email
      end

      csv << [""]
      csv << ["Beta Signups"]

      beta_signups = BetaSignup.all.asc(:id)
      beta_signups.each do |signup|
        unless user_emails.include?(signup.email.downcase)
          csv << [signup.email.downcase]
        end
      end
    end
  end

end
