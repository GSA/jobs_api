class Api::V1::PositionOpeningsController < ApplicationController
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

  def search
    @position_openings = PositionOpening.search_for(params.slice(:query, :organization_id, :size, :from, :hl))
    render json: @position_openings
  end

  add_transaction_tracer :search
end
