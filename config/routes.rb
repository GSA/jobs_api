JobsApi::Application.routes.draw do
  scope module: 'api/v1',
        constraints: ApiConstraint.new(version: 1),
        defaults: {format: :json} do
    get '/search(.json)' => 'position_openings#search', format: false
  end

  scope module: 'api/v2',
        constraints: ApiConstraint.new(version: 2, default: true),
        defaults: {format: :json} do
    get '/search(.json)' => 'position_openings#search', format: false
  end
end