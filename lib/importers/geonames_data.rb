class GeonamesData
  LOCATION, LAT, LON, STATE = 1, 4, 5, 10

  def initialize(filename)
    @filename = filename
  end

  def import
    geonames = File.open(@filename).collect do |line|
      fields = line.split("\t")
      location = fields[LOCATION]
      state = fields[STATE]
      lat = fields[LAT].to_f
      lon = fields[LON].to_f
      { type: 'geoname', location: geoname_normalized_city(location), state: state, geo: { lat: lat, lon: lon } }
    end
    puts "Importing #{geonames.size} geonames ..."
    running_total = 0
    geonames.in_groups_of(1000, false) do |group|
      Geoname.import group
      running_total += group.count
      puts "#{running_total}..."
    end
  end

  def geoname_normalized_city(location)
    location.sub(/,? ?D\.? ?C\.?/, '')
  end

end