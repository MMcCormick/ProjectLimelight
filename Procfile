web:         bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker:      bundle exec rake resque:work QUEUE=popularity,soulmate_user,soulmate_topic,images
scheduler:   bundle exec rake resque:scheduler