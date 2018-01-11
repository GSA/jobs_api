set :output, { error: "log/cron_error.log", standard: "log/cron.log" }

every 1.day, at: zoned_time("12:00 am") do
  rake "position_openings:delete_expired_position_openings"
end
