class Api::V2::PositionOpeningsController < ApplicationController
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

  def search
    @position_openings = PositionOpening.search_for(params.slice(:query, :organization_id, :tags, :size, :from, :hl, :lat_lon))
    render
  end

  add_transaction_tracer :search
end
