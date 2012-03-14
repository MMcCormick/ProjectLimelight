web:         bundle exec rails server thin -p $PORT
worker:      bundle exec rake resque:work QUEUE=fast,medium,slow,popularity,neo4j,soulmate,feeds,images,notifications
scheduler:   bundle exec rake resque:scheduler