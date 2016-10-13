json.array!(@flags) do |flag|
  json.extract! flag, :id, :name, :color, :workflow_id, :description
  json.url flag_url(flag, format: :json)
end
