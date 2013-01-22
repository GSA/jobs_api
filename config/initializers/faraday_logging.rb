ActiveSupport::Notifications.subscribe('request.faraday') do |name, start_time, end_time, _, env|
  url = env[:url]
  http_method = env[:method].to_s.upcase
  duration = end_time - start_time
  Rails.logger.info('[%s] %s %s (%.3f s)' % [url.host, http_method, url.request_uri, duration])
end