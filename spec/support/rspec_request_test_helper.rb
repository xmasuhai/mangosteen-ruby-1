module RequestTestHelper
  # Sign in a user. # 已替换为在 `User` 模型中 `generate_auth_header` 方法
  # @param [Object] user Param documentation.
  # @return [Hash]
  def sign_in(user)
    post "/api/v1/session", params: { email: user.email, code: '123456' }
    json = JSON.parse response.body
    jwtString = json["jwt"]
    { "Authorization" => "Bearer #{jwtString}" }
  end
end
