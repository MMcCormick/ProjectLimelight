web:         bundle exec rails server thin -p $PORT
worker:      bundle exec rake resque:work QUEUE=fast,neo4j,medium,slow,popularity,feeds,images,notifications
scheduler:   bundle exec rake resque:scheduler