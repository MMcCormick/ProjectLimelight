class TestingController < ApplicationController

  def test
    RecalculatePopularity.perform('day')

    #pop_talks = Talk.all.desc(:pw).limit(3)
    #pop_link = Link.all.desc(:pw).limit(3)
    #pop_pics = Picture.all.desc(:pw).limit(3)
    #pop_vids = Video.all.desc(:pw).limit(3)
    #NewsletterMailer.weekly_email(current_user, pop_talks, pop_link, pop_pics, pop_vids).deliver if current_user.weekly_email
  end

end