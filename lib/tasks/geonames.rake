namespace :geonames do
  desc 'Import Geonames tab-delimited file of US locations'
  task :import, [:filename] => :environment do |t, args|
    if args.filename.nil?
      puts 'usage: rake geonames:import[us.txt]'
    else
      importer = GeonamesData.new(args.filename)
      importer.import
    end
  end

  desc 'Recreate geonames index'
  task recreate_index: :environment do
    Geoname.delete_search_index if Geoname.search_index.exists?
    Geoname.create_search_index
  end
end