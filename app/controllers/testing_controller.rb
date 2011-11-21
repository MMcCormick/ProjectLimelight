class TestingController < ApplicationController

  def test
    pop_talks = Talk.all.desc(:pw).limit(3)
    pop_news = News.all.desc(:pw).limit(3)
    pop_pics = Picture.all.desc(:pw).limit(3)
    pop_vids = Video.all.desc(:pw).limit(3)
    NewsletterMailer.weekly_email(current_user, pop_talks, pop_news, pop_pics, pop_vids).deliver
  end

end