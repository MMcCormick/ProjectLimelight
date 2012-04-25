web:         bundle exec rails server thin -p $PORT -e $RACK_ENV
scheduler:   bundle exec rake resque:scheduler
worker:      bundle exec rake resque:work QUEUE=fast,neo4j,medium,datasift,slow,popularity,feeds,images,notifications
datasift:    bundle exec rake datasift:consume_stream