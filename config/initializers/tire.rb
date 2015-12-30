service_credentials = JSON.parse(ENV['VCAP_SERVICES']) rescue nil
if service_credentials
  Tire.configure do
    url service_credentials['elasticsearch-swarm-1.7.1'].first['credentials']['uri']
  end
end

PositionOpening.create_search_index unless PositionOpening.search_index.exists?
Geoname.create_search_index unless Geoname.search_index.exists?
