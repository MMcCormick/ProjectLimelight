web:         bundle exec rails s puma -p $PORT -e $RACK_ENV
scheduler:   bundle exec rake resque:scheduler
worker:      bundle exec rake resque:work QUEUE=fast,neo4j,medium,mailer,slow,popularity,feeds,images,notifications