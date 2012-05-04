require 'net/http'
require 'uri'

class DatasiftRecompile

  @queue = :datasift

  def self.perform()
    topics = Topic.where(:datasift_enabled => true)
    csdl_tags = topics.map {|t| t.datasift_tags}

    csdl = "interaction.content ANY \"#{csdl_tags.join(',')}\"
            AND
            language.tag == \"en\"
            AND
            twitter.retweet.count >= 5
            AND
            links.retweet_count >= 30
            AND
            links.age <= 172800
    "

    postData = Net::HTTP.post_form(
            URI.parse('http://api.datasift.com/compile'),
            {
                    'csdl' => csdl,
                    'username' => 'marbemac',
                    'api_key' => '6acfce1c072652c8316f7d555c2d74d3'
            }
    )

    datasift = SiteData.where(:name => 'datasift').first
    unless datasift
      datasift = SiteData.new
      datasift.name = 'datasift'
    end
    datasift.data = JSON.load(postData.body)
    datasift.data['topic_count'] = topics.length
    datasift.save
  end
end