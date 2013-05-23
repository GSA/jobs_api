#Tire.configure { logger STDERR, level: 'debug' }
PositionOpening.create_search_index unless PositionOpening.search_index.exists?
Geoname.create_search_index unless Geoname.search_index.exists?