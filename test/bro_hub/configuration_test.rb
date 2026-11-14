require "test_helper"

class BroHub::ConfigurationTest < ActiveSupport::TestCase
  Plain = Class.new
  WithCurrentUser = Class.new { def current_user = :from_method }

  teardown { Object.send(:remove_const, :Current) if Object.const_defined?(:Current, false) }

  test "default current_user calls the controller's current_user" do
    assert_equal :from_method, BroHub::Configuration.new.current_user.call(WithCurrentUser.new)
  end

  test "default current_user falls back to Current.user (Rails 8 authentication)" do
    Object.const_set(:Current, Class.new { def self.user = :from_current })
    assert_equal :from_current, BroHub::Configuration.new.current_user.call(Plain.new)
  end

  test "default current_user is nil with neither" do
    assert_nil BroHub::Configuration.new.current_user.call(Plain.new)
  end

  test "default label tries email_address too" do
    assert_equal "a@b.c", BroHub::Configuration.new.user_label.call(Struct.new(:email_address).new("a@b.c"))
  end
end
