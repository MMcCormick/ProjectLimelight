web:         bundle exec rails server thin -p $PORT
worker:      bundle exec rake resque:work QUEUE=popularity,soulmate_user,soulmate_topic,images,notifications,slow
scheduler:   bundle exec rake resque:scheduler