class CrawlerGo

  @queue = :fast_limelight

  class << self

    def perform()
      sources = CrawlerSource.where(:status => 'active')
      sources.each do |s|
        feed = Feedzirra::Feed.fetch_and_parse(s.url)

        next unless feed && feed != 0 && feed != '0'

        next unless feed.etag || feed.last_modified

        # skip this source if it has not beed modified since our last crawl
        if (feed.etag && feed.etag == s.etag) || (s.last_modified && s.last_modified && feed.last_modified == s.last_modified)
          s.last_modified = feed.last_modified
          s.etag = feed.etag
          s.last_crawled = Time.now
          s.save
          next
        end

        feed.entries.each do |entry|

          # skip this entry if it is older than the last time we crawled
          next if s.last_crawled && entry.published && s.last_crawled && entry.published <= s.last_crawled

          Resque.enqueue_in(rand(13.minutes), CrawlerPushPost, entry.url, s.id.to_s)

        end

        s.last_modified = feed.last_modified
        s.etag = feed.etag
        s.last_crawled = Time.now
        s.save
      end
    end
  end
end