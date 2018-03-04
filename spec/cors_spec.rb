# frozen_string_literal: true

require 'rails_helper'

class DummyController < ApplicationController
  def show
    render plain: 'text'
  end
end

describe DummyController, type: :request do
  describe '#show' do
    before do
      Rails.application.routes.draw do
        get '/show', to: 'dummy#show'
      end

      get '/show', params: nil, headers: { 'HTTP_ORIGIN' => 'http://www.example.com' }
    end

    after do
      Rails.application.reload_routes!
    end

    it 'should respond with an "Access-Control-Allow-Origin" header' do
      expect(headers.keys).to include('Access-Control-Allow-Origin')
    end

    %w[GET OPTIONS].each do |verb|
      it "should respond with a 'Access-Control-Allow-Methods' header allowing #{verb}" do
        allowed_methods = headers['Access-Control-Allow-Methods'].split(', ')
        expect(allowed_methods).to include(verb)
      end
    end
  end
end
