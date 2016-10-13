json.array!(@users) do |user|
  json.extract! user, :id, :email, :password, :password_confirmation, :admin, :disabled
  json.url user_url(user, format: :json)
end
