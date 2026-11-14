require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

# Stand-ins for real Bro gems: Alpha and Beta live inside the hub, Gamma is mounted on its own.
%w[ alpha beta gamma ].each do |name|
  $LOAD_PATH.unshift File.expand_path("../../support/fake_bros/#{name}/lib", __dir__)
  require name
end

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.action_controller.include_all_helpers = false
    config.autoload_lib(ignore: %w[assets tasks])


    config.secret_key_base = "dummy-secret-key-base-for-bro-hub-tests-0123456789"
  end
end
