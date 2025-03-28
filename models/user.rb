require "bcrypt"

class User < ActiveRecord::Base
  has_many :messages, dependent: :destroy

  has_secure_password
end
