web:           bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker:        bundle exec rake resque:work QUEUE=popularity,soulmate_user,soulmate_topic,images,notifications,slow
neo4jworker:   bundle exec rake resque:work QUEUE=neo4j
scheduler:     bundle exec rake resque:scheduler