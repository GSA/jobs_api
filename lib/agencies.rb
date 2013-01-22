module Agencies
  HOST = 'http://search.usa.gov'.freeze
  ENDPOINT = '/api/v1/agencies/search'.freeze

  ONE_WEEK = 604800

  @agency_api_connection = Faraday.new HOST do |conn|
    conn.request :json
    conn.response :json
    conn.response :caching do
      ActiveSupport::Cache::FileStore.new File.join(Rails.root, 'tmp', 'cache'), namespace: 'agency_api', expires_in: ONE_WEEK
    end
    conn.use :instrumentation
    conn.adapter :net_http_persistent
  end

  def self.find_organization_id(organization_str)
    @agency_api_connection.get(ENDPOINT, query: organization_str).body['organization_code']
  rescue Exception => e
    Rails.logger.error e
    nil
  end

end