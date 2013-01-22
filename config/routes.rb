JobsApi::Application.routes.draw do
  namespace :api do
    scope module: :v1,
          constraints: ApiConstraint.new(version: 1, default: true),
          defaults: {format: :json} do
      get '/position_openings/search(.json)' => 'position_openings#search', format: false
    end
  end
end
