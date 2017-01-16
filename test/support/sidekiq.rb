# Use Sidekiq's test fake that pushes all jobs into a jobs array
require "sidekiq/testing"
Sidekiq::Testing.fake!
