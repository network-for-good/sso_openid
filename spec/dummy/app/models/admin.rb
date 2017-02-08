class Admin
  attr_accessor :oauth_token, :oauth_expires_at, :uid

  def save
    true
  end

  def uid
    'abc-123'
  end

  def id
    1
  end
end