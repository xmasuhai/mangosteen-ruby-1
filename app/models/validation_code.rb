class ValidationCode < ApplicationRecord
  # email必填
  validates :email, presence: true
end
