web:         bundle exec rails server thin -p $PORT
worker:      bundle exec rake resque:work QUEUE=popularity,neo4j,soulmate,feeds,images,notifications,slow
scheduler:   bundle exec rake resque:scheduler