class User < ApplicationRecord
  validates :email, presence: true

  # User 自己生成 JWT.
  # @return [String]
  def generate_jwt
    payload = { user_id: self.id, email: self.email }
    hmac_secret = Rails.application.credentials.hmac_secret
    JWT.encode(payload, hmac_secret, "HS256")
  end

  # 生成 JWT 的 HTTP 头.
  # @return [Hash]
  def generate_auth_header
    { "Authorization": "Bearer #{self.generate_jwt}" }
  end
end
