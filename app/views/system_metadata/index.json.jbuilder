json.array!(@system_metadata) do |system_metadatum|
  json.extract! system_metadatum, :id
  json.url system_metadatum_url(system_metadatum, format: :json)
end
