web:           bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker:        bundle exec rake resque:work QUEUE=neo4j,popularity,soulmate_user,soulmate_topic,images,notifications,slow
scheduler:     bundle exec rake resque:scheduler
neo4j_worker:  bundle exec rake resque:work QUEUE=neo4j