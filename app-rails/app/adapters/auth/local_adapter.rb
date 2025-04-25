class Auth::LocalAdapter
  def initialize
    # In-memory user store, no database interaction here
    @users = [
      { email: "dev@example.com", password: "password", confirmed: true }
    ]
  end

  def initiate_auth(email, password)
    # Find the user in the in-memory list
    user = @users.find { |u| u[:email] == email }

    # If no user is found, simulate user creation
    if user.nil?
      Rails.logger.info "Simulating creation of new user for email: #{email}"

      # Add the new user to the in-memory users array (no DB interaction)
      user = { email: email, password: password, confirmed: true }

      # Simulate adding the user to the array
      @users << user
    end

    # Check if the password matches
    if user[:password] != password
      raise Auth::Errors::InvalidCredentials.new("Incorrect password")
    elsif !user[:confirmed]
      raise Auth::Errors::UserNotConfirmed.new("User not confirmed")
    end

    # Simulate a successful auth response
    {
      uid: "local-dev-user-uid",
      provider: "local",
      token: generate_token(user)
    }
  end

  def generate_token(user)
    # Simulate token generation (JWT or other logic)
    JWT.encode({ user_id: user[:email], exp: 24.hours.from_now.to_i }, "secret_key")
  end
end
