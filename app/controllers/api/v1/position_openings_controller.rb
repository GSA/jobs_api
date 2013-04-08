class Api::V1::PositionOpeningsController < ApplicationController
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

  def search
    @position_openings = PositionOpening.search_for(search_params)
    render
  end

  add_transaction_tracer :search

  private

  def search_params
    params.slice(:query, :organization_id, :size, :from, :hl).merge(source: 'usajobs')
  end
end
