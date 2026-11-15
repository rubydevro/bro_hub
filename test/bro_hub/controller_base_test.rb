require "test_helper"

class BroHub::ControllerBaseTest < ActiveSupport::TestCase
  # A host controller like one using Pundit: every action must call `authorize`, or the request fails.
  class PunditHost < ActionController::Base
    after_action :verify_authorized
    after_action :verify_policy_scoped
    def verify_authorized = raise("AuthorizationNotPerformedError")
    def verify_policy_scoped = raise("PolicyScopingNotPerformedError")
  end

  test "opts out of the host's verify_authorized and verify_policy_scoped" do
    base = Class.new(PunditHost) { include BroHub::ControllerBase }
    callbacks = base._process_action_callbacks.select { |c| c.kind == :after }.map(&:filter)
    assert_not_includes callbacks, :verify_authorized
    assert_not_includes callbacks, :verify_policy_scoped
    assert_includes PunditHost._process_action_callbacks.map(&:filter), :verify_authorized
  end

  test "adds the layout and CSRF protection" do
    base = Class.new(ActionController::Base) { include BroHub::ControllerBase }
    assert_includes base.ancestors, BroHub::Layout
    assert_includes base._process_action_callbacks.map(&:filter), :verify_authenticity_token
  end

  test "is a no-op without Pundit" do
    assert_nothing_raised { Class.new(ActionController::Base) { include BroHub::ControllerBase } }
  end
end
