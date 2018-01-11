namespace :jobs do
  desc 'Import USAJobs XML file'
  task :import_usajobs_xml, [:filename] => :environment do |t, args|
    if args.filename.nil?
      puts 'usage: rake jobs:import_usajobs_xml[filename.xml]'
    else
      importer = UsajobsData.new(args.filename)
      importer.import
    end
  end

  desc 'Import Neogov YAML file containing agency info'
  task :import_neogov_rss, [:yaml_filename] => :environment do |t, args|
    begin
      YAML.load(File.read(args.yaml_filename)).each do |config|
        agency, details = config
        tags, organization_id, organization_name = details['tags'], details['organization_id'], details['organization_name']
        if agency.blank? or tags.blank? or organization_id.blank?
          puts 'Agency, tags, and organization ID are required for each record. Skipping record....'
        else
          importer = NeogovData.new(agency, tags, organization_id, organization_name)
          importer.import
          puts "Imported jobs for #{agency} at #{Time.now}"
        end
      end
    rescue Exception => e
      puts "Trouble running import script: #{e}"
      puts e.backtrace
      puts '-'*80
      puts "usage: rake jobs:import_neogov_rss[yaml_filename]"
      puts "Example YAML file syntax:"
      puts "bloomingtonmn:"
      puts "\ttags: city tag_2"
      puts "\torganization_id: US-MN:CITY-BLOOMINGTON"
      puts "\torganization_name: City of Bloomington"
      puts "ohio:"
      puts "\ttags: state tag_3"
      puts "\torganization_id: US-OH"
    end
  end

  desc 'Recreate position openings index'
  task recreate_index: :environment do
    PositionOpening.delete_search_index if PositionOpening.search_index_exists?
    PositionOpening.create_search_index
  end

  desc 'Delete expired position openings'
  task delete_expired_position_openings: :environment do
    PositionOpening.delete_expired_docs
  end
end
