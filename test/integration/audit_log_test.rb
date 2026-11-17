require "test_helper"

class AuditLogTest < ActionDispatch::IntegrationTest
  setup do
    @alpha = BroHub::Audit.record(source: :alpha, event: :keys_purged, user: "jane@example.com", target: "posts/*", count: 3,
      reason: "stale", sample: [ "posts/1", "posts/2" ])
    @beta = BroHub::Audit.record(source: :beta, event: :proposal_created, user: "joe@example.com", target: "stripe.key")
    BroHub::Audit.record(source: :gamma, event: :seen, user: "nobody@example.com", target: "invisible")
  end

  test "nobody signed in is refused" do
    get "/hub/audit"
    assert_response :forbidden
    assert_no_match(/posts/, response.body)
  end

  test "each person sees the rows of the gems they may audit, and only those" do
    sign_in_as "auditor"
    get "/hub/audit"
    assert_response :success
    assert_select ".bh-row", /Keys purged/
    assert_select ".bh-row", text: /Proposal created/, count: 0
    assert_select ".bh-row", text: /invisible/, count: 0

    sign_in_as "staff"
    get "/hub/audit"
    assert_select ".bh-row", /Proposal created/
    assert_select ".bh-row", text: /Keys purged/, count: 0
  end

  test "a gem nobody may audit through the hub never shows up, even by id" do
    sign_in_as "auditor"
    gamma = BroHub::AuditEvent.find_by(source: "gamma")
    get "/hub/audit/#{gamma.id}"
    assert_response :not_found
    get "/hub/audit/#{@beta.id}"
    assert_response :not_found
  end

  test "an entry has its own page" do
    sign_in_as "auditor"
    get "/hub/audit/#{@alpha.id}"
    assert_response :success
    assert_select ".bh-title", /Keys purged/
    assert_select ".bh-cmd-code", /posts\/\*/
    assert_select ".bh-cmd-code", /posts\/2/
    assert_select ".bh-dl", /jane@example.com/
    assert_select ".bh-dl", /stale/
  end

  test "filters by gem, event, user and text" do
    sign_in_as "auditor"
    BroHub::Audit.record(source: :alpha, event: :value_viewed, user: "amy@example.com", target: "users/9")

    get "/hub/audit", params: { event: "value_viewed" }
    assert_select ".bh-row", /users\/9/
    assert_select ".bh-row", text: /posts/, count: 0

    get "/hub/audit", params: { user: "jane@example.com" }
    assert_select ".bh-row", /posts/
    assert_select ".bh-row", text: /users\/9/, count: 0

    get "/hub/audit", params: { q: "stale" }
    assert_select ".bh-row", /posts/
    assert_select ".bh-row", text: /users\/9/, count: 0

    get "/hub/audit", params: { q: "%" }
    assert_select ".bh-row", text: /posts/, count: 0

    get "/hub/audit", params: { source: "beta" }
    assert_select ".bh-row", text: /posts/, count: 0
  end

  test "pages through long logs" do
    sign_in_as "auditor"
    (BroHub::AuditEventsController::PER_PAGE + 5).times { |n| BroHub::Audit.record(source: :alpha, event: :value_viewed, user: "a", target: "k#{n}") }

    get "/hub/audit"
    assert_select "a", "Older →"
    get "/hub/audit", params: { page: 1 }
    assert_select "a", "← Newer"
    assert_select "a", text: "Older →", count: 0
  end

  test "the sidebar links to it for people who may audit something" do
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select ".bh-group-label", "Bro Hub"
    assert_select "a.bh-nav[href='/hub/audit']", /Audit log/

    get "/hub/audit"
    assert_select "a.bh-nav.is-active[href='/hub/audit']"
  end

  test "the sidebar has no link when nothing can be audited by this person" do
    registry = BroHub.registry
    registry.define_singleton_method(:audited_by) { |_user| [] }
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select "a.bh-nav[href='/hub/audit']", count: 0
  ensure
    registry.singleton_class.remove_method(:audited_by)
  end

  test "the audit log is never cached" do
    sign_in_as "auditor"
    get "/hub/audit"
    assert_equal "no-store", response.headers["Cache-Control"]
  end
end
