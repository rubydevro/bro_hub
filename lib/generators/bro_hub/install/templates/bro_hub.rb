BroHub.configure do |config|
  # How to find the signed-in user. The default calls `current_user` on the controller when it has one.
  # config.current_user = ->(controller) { controller.current_user }

  # What to show at the top right.
  # config.user_label = ->(user) { user.email }

  # Which controller the dashboard's own pages inherit from (so your authentication runs).
  # config.parent_controller = "::ApplicationController"
end
