module RequestTestHelper
  # Sign in a user.
  # @param [Object] user Param documentation.
  # @return [Hash]
  def sign_in(user)
    post "/api/v1/session", params: { email: user.email, code: '123456' }
    json = JSON.parse response.body
    jwtString = json["jwt"]
    { "Authorization" => "Bearer #{jwtString}" }
  end
end
