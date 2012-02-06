#class WeeklyEmail
#  include Resque::Plugins::UniqueJob
#
#  @queue = :slow
#
#  def self.perform
#    users = User.all
#    pop_talks = Talk.all.desc(:pw).limit(3)
#    pop_link = Link.all.desc(:pw).limit(3)
#    pop_pics = Picture.all.desc(:pw).limit(3)
#    pop_vids = Video.all.desc(:pw).limit(3)
#    users.each do |user|
#      NewsletterMailer.weekly_email(user, pop_talks, pop_link, pop_pics, pop_vids).deliver if user.weekly_email
#    end
#  end
#end