json.array! @position_openings do |position_opening|
  json.(position_opening, :id, :position_title, :organization_name, :rate_interval_code, :minimum, :maximum, :start_date, :end_date, :locations, :url)
end