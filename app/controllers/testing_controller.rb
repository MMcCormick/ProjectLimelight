require "net/http"

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    #Resque.enqueue(TestJob)

    Topic.all.update(:followers_count => 0)

    users = User.all
    users.each do |u|
      node = Neo4j.neo.get_node_index('users', 'uuid', u.id.to_s)
      if node
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'like')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'affinity')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'follow')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'mentions')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'created')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'talked')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end

        u.following_users.each do |fu|
          fun = User.find(fu)
          if fun
            Neo4j.follow_create(u.id.to_s, fun.id.to_s, 'users', 'users')
          else
            u.following_users.delete(fu)
          end
          u.following_users_count = u.following_users.length
        end

        u.following_topics.each do |fu|
          fut = Topic.find(fu)

          if fut
            fut.followers_count += 1
            fut.save
            Neo4j.follow_create(u.id.to_s, fut.id.to_s, 'users', 'topics')
          else
            u.following_topics.delete(fu)
          end
          u.following_topics_count = u.following_topics.length
        end

        u.save

      end
    end

    #topic = Topic.find('4fc5ac6e2619465c0c000001')
    #topic.freebase_repopulate
    #foo = 'foo'

    #topic = Topic.where(:freebase_guid => {"$exists" => true}).first
    #test = topic.freebase
    #test = Ken::Topic.get('/organization/organization')

    #feed = Feedzirra::Feed.fetch_and_parse("http://feeds.washingtonpost.com/rss/world")
    #foo = 'bar'
    #facebook = Topic.where(:name => 'Xbox Live').first
    #facebook.fetch_freebase

    #search = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&limit=1&query=google")

    #resource = Ken::Topic.get('/en/google')
    #t = Ken.session.mqlread({
    #      :id => '/en/facebook',
    #      :type => "/common/topic",
    #      :mid => nil,
    #      :guid => nil,
    #      :notable_for => []
    #    }, {:extended => true})
    #types = resource.types
    #test = resource.mid
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