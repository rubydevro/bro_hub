require "test_helper"

class BroHub::AuditTest < ActiveSupport::TestCase
  User = Struct.new(:email)

  test "records who did what, where, and why" do
    event = BroHub::Audit.record(source: :alpha, event: :keys_purged, user: User.new("jane@example.com"),
      context: "Rails.cache", target: "posts/*", count: 3, reason: "stale", ip: "10.0.0.7", sample: [ "posts/1" ])

    event.reload
    assert_equal "alpha", event.source
    assert_equal "keys_purged", event.event
    assert_equal "jane@example.com", event.user_label
    assert_equal Rails.env.to_s, event.environment
    assert_equal [ "Rails.cache", "posts/*", 3, "stale", "10.0.0.7" ], [ event.context, event.target, event.count, event.reason, event.ip ]
    assert_equal({ "sample" => [ "posts/1" ] }, event.details)
  end

  test "a String user is stored as it is" do
    assert_equal "deploy", BroHub::Audit.record(source: :alpha, event: :x, user: "deploy").user_label
  end

  test "blank optional values are stored as nil, and details always exist" do
    event = BroHub::Audit.record(source: :alpha, event: :x, user: "a", reason: "", context: "", ip: "").reload
    assert_nil event.reason
    assert_nil event.context
    assert_nil event.ip
    assert_equal({}, event.details)
  end

  test "entries are append-only" do
    event = BroHub::Audit.record(source: :alpha, event: :x, user: "a")
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.update!(user_label: "someone else") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.destroy }
  end

  test "needs a source, an event and an environment" do
    assert_raises(ActiveRecord::RecordInvalid) { BroHub::Audit.record(source: "", event: :x, user: "a") }
    assert_raises(ActiveRecord::RecordInvalid) { BroHub::Audit.record(source: :alpha, event: "", user: "a") }
  end

  test "fails closed: logs the entry and raises when it can't be written" do
    logged = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(logged)
    failing = Class.new(BroHub::AuditEvent) { def self.name = "Failing"; before_create { raise "disk full" } }

    error = assert_raises(RuntimeError) { BroHub::Audit.record(source: :alpha, event: :x, user: "a", target: "k", model: failing) }
    assert_equal "disk full", error.message
    assert_match(/could not write the audit log.*disk full/, logged.string)
    assert_match(/"k"/, logged.string)
  ensure
    Rails.logger = original
  end

  test "a follow-up row is linked to its parent, once per kind" do
    parent = BroHub::Audit.record(source: :alpha, event: :proposal_created, user: "a")
    BroHub::Audit.record(source: :alpha, event: :proposal_deployed, user: "deploy", parent: parent)

    assert_equal parent, BroHub::AuditEvent.find_by(event: "proposal_deployed").parent
    assert_raises(ActiveRecord::RecordNotUnique) do
      BroHub::Audit.record(source: :alpha, event: :proposal_deployed, user: "deploy", parent: parent)
    end
  end

  test "a gem's own subclass reads only its own rows and stamps its source" do
    mine = Class.new(BroHub::AuditEvent) { def self.name = "Mine"; default_scope { where(source: "alpha") } }
    BroHub::Audit.record(source: :alpha, event: :x, user: "a")
    BroHub::Audit.record(source: :beta, event: :x, user: "a")

    assert_equal 1, mine.count
    assert_equal 2, BroHub::AuditEvent.count
    assert_equal "alpha", mine.create!(event: "y", environment: "test").source
  end

  test "ready? is true once the table exists" do
    assert BroHub::Audit.ready?
  end

  test "a source is shown by its section's name when it has one" do
    assert_equal "Alpha", BroHub::Audit.record(source: :alpha, event: :x, user: "a").source_name
    assert_equal "Gone bro", BroHub::Audit.record(source: :gone_bro, event: :x, user: "a").source_name
  end
end
