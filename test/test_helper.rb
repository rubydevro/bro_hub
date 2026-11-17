# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "rails/test_help"
require "bro_hub/testing"

# The audit table, created fresh on every run (cheap with SQLite).
BroHub::Testing.load_schema

class ActiveSupport::TestCase
  setup { BroHub::AuditEvent.delete_all }

  # Sets config values for the block, then puts them back.
  def with_config(**values)
    originals = values.keys.index_with { |name| BroHub.config.public_send(name) }
    values.each { |name, value| BroHub.config.public_send(:"#{name}=", value) }
    yield
  ensure
    originals.each { |name, value| BroHub.config.public_send(:"#{name}=", value) }
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(role)
    post "/role", params: { role: role, return_to: "/" }
  end
end
