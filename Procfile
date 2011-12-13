web:         bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker:      exec bundle exec rake resque:work QUEUE=popularity,soulmate_user,soulmate_topic,images,notifications,slow
scheduler:   bundle exec rake resque:scheduler