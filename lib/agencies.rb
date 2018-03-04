# frozen_string_literal: true

module Agencies
  ENDPOINT = '/api/v2/agencies/search'
  HOST = 'https://search.usa.gov'

  ONE_DAY = 86_400

  @agency_api_connection = Faraday.new HOST do |conn|
    conn.request :json
    conn.response :json
    conn.response :caching do
      ActiveSupport::Cache::FileStore.new File.join(Rails.root, 'tmp', 'cache'), namespace: 'agency_api_v2', expires_in: ONE_DAY
    end
    conn.use :instrumentation
    conn.adapter :net_http_persistent
  end

  def self.find_organization_ids(organization_str)
    @agency_api_connection.get(ENDPOINT, query: organization_str).body['organization_codes']
  rescue StandardError => e
    Rails.logger.error e
    nil
  end
end
