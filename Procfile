web: bundle exec rackup config.ru -p $PORT
scheduler: bundle exec rake resque:scheduler
worker: bundle exec rake resque:work QUEUE=*
