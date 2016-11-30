user = User.new
user.email = ENV["admin_user_name"]
user.password = ENV["admin_user_pass"]
user.password_confirmation = ENV["admin_user_pass"]
user.admin = true
user.save
