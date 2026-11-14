BroHub.configure do |config|
  # How to find the signed-in user. The default calls `current_user` on the controller when it has one,
  # and falls back to `Current.user` (Rails 8 authentication generator).
  # config.current_user = ->(controller) { controller.current_user }

  # What to show at the top right.
  # config.user_label = ->(user) { user.email }   # Rails 8 auth generator: user.email_address (also tried by default)

  # Which controller the dashboard's own pages inherit from (so your authentication runs).
  # config.parent_controller = "::ApplicationController"
end
