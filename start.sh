redis-server &
~/.rbenv/shims/bundle exec sidekiq -l log/sidekiq.log &
~/.rbenv/shims/bundle exec rails s &
