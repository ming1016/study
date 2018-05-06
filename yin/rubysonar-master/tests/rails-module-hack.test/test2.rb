class OauthedUser
  include ActiveModel::SecurePassword
  has_secure_password(validations: false)
end
