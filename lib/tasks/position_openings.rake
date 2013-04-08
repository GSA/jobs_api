namespace :jobs do
  desc 'Import USAJobs XML file'
  task :import_usajobs_xml, [:filename] => :environment do |t, args|
    if args.filename.nil?
      message = 'usage: rake jobs:import_usajobs_xml[filename.xml]'
      Rails.logger.error message
      puts message
    else
      importer = UsajobsData.new(args.filename)
      importer.import
    end
  end

  desc 'Import Neogov RSS file'
  task :import_neogov_rss, [:agency, :filename, :tags, :organization_id, :organization_name] => :environment do |t, args|
    if args.agency.blank? or args.filename.blank? or args.tags.blank? or args.organization_id.blank?
      message = 'usage: rake jobs:import_neogov_rss[agency,filename.xml,tags,organization_id,organization_name]'
      Rails.logger.error message
      puts message
    else
      importer = NeogovData.new(args.agency, args.filename, args.tags, args.organization_id, args.organization_name)
      importer.import
    end
  end

  desc 'Recreate position openings index'
  task recreate_index: :environment do
    PositionOpening.delete_search_index if PositionOpening.search_index.exists?
    PositionOpening.create_search_index
  end
end