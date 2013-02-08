namespace :jobs do
  desc 'Import USAJobs XML file'
  task :import_xml, [:filename] => :environment do |t, args|
    if args.filename.nil?
      Rails.logger.error 'usage: rake jobs:position_openings:import_xml[filename.xml]'
    else
      importer = UsajobsData.new(args.filename)
      importer.import
    end
  end

  desc 'Recreate position openings index'
  task recreate_index: :environment do
    PositionOpening.delete_search_index if PositionOpening.search_index.exists?
    PositionOpening.create_search_index
  end
end