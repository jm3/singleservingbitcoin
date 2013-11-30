web: bundle exec puma -p $PORT -e $RACK_ENV -t 0:16
scheduler: bundle exec rake resque:scheduler
worker: bundle exec rake resque:work QUEUE=*
