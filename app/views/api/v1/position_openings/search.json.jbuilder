json.array! @position_openings do |position_opening|
  json.id "#{position_opening[:external_id]}"
  json.(position_opening, :position_title, :organization_name, :rate_interval_code, :minimum, :maximum, :start_date, :end_date, :locations)
end