require "net/http"

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    #Resque.enqueue(TestJob)

    post = Post.first
    updates = {"$set" => { :feed_id => post.user_id, :root_id => post.root_id, :root_type => post.root_type, :last_response_time => Time.now }}
    updates["$addToSet"] = { :responses => post.id } unless post.is_root?
    updates["$inc"] = { :strength => 1 }

    FeedContributeItem.collection.where(:feed_id => BSON::ObjectId('4fc22cc7dfe294fa2a4aa268'), :root_id => post.root_id).upsert(:feed_id => post.user_id, :root_id => post.root_id)

    #feed = Feedzirra::Feed.fetch_and_parse("http://feeds.washingtonpost.com/rss/world")
    #foo = 'bar'
    #facebook = Topic.where(:name => 'Xbox Live').first
    #facebook.fetch_freebase

    #search = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&limit=1&query=google")

    #resource = Ken.get('/en/google')
    #types = resource.types
    #foo = 'bar'
    #resource.views.each do |view|
    #  type = view.type
    #  view.attributes.each do |a|
    #    name = a.property.name
    #    values = a.values
    #    foo = 'bar'
    #  end
    #end

    #t = Ken::Topic.get('/guid/9202a8c04000641f80000000002e875e')
    #t = Ken::Topic.get('/en/food_and_drug_administration')
    #name = t.name
    #description = t.description
    #aliases = t.aliases
    #websites = t.webpages
    #url = t.url
    #thumbnail = t.thumbnail
    #types = t.types
    #views = t.views
    #properties = t.properties
    #attributes = t.attributes

    #response = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&query=#{URI::encode('U.S. Food and Drug Administration')}&limit=1")
    #t = Ken::Topic.get(response['result'].first['mid'])
    ##guid = t.guid
    #name = t.name
    #description = t.description
    #aliases = t.aliases
    #websites = t.webpages
    #url = t.url
    #thumbnail = t.thumbnail
    #types = t.types
    #views = t.views
    #properties = t.properties
    #attributes = t.attributes

    #topic = Topic.find('4fbe56102619467425000002')
    #topic.fetch_freebase(true)

  end

end