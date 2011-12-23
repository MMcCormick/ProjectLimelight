class Neo4j

  class << self
    def neo
      @neo ||= ENV['NEO4J_REST_URL'] ? Neography::Rest.new(ENV['NEO4J_REST_URL']) : Neography::Rest.new
    end
  end

end