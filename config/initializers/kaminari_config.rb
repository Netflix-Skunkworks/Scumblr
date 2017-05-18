Kaminari.configure do |config|
  config.default_per_page = 10
  config.window = 2
  config.param_name = 'q[page]'
end
