class ApiConstraint
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(request)
    @default ||
      (request.headers['Accept'] &&
        request.headers['Accept'].include?("application/vnd.usagov.position_openings.v#{@version}"))
  end
end