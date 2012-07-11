require "net/http"

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    @count1 = 0
    @count2 = 0

    Resque.enqueue(TestJob)

    #Topic.all.each do |t|
    #  node1 = Neo4j.neo.get_node(t.neo4j_id)
    #  node2 = Neo4j.neo.get_node_index('topics', 'uuid', t.id.to_s)
    #  unless node1
    #    @count1 += 1
    #  end
    #  unless node2
    #    @count2 += 1
    #  end
    #end

  end

end