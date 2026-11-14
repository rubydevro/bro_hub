require "test_helper"

class ShellTest < ActionDispatch::IntegrationTest
  test "the hub root sends a signed-in person to their first section" do
    sign_in_as "auditor"
    get "/hub"
    assert_redirected_to "/hub/alpha"

    sign_in_as "staff"
    get "/hub"
    assert_redirected_to "/hub/beta"
  end

  test "nobody signed in sees nothing" do
    get "/hub"
    assert_response :forbidden
    assert_no_match(/Alpha|Beta/, response.body)
  end

  test "engines are mounted under the hub and render inside the shell" do
    sign_in_as "auditor"
    get "/hub/alpha/flagged"
    assert_response :success
    assert_select ".bh-top", /powered by\s+DeadBro/
    assert_select ".bh-top .bh-user", "auditor@example.com"
    assert_select ".bh-crumb", /Alpha \/ Flagged/
    assert_select ".bh-title", /Flagged/
    assert_select "title", "Flagged · Alpha · Bro Hub"
  end

  test "the sidebar lists every section the person may see, with the right links" do
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select ".bh-group-label", text: "Alpha · audit"
    assert_select ".bh-group-label", text: "Beta · config"
    assert_select "a.bh-nav[href='/hub/alpha']", /Sessions/
    assert_select "a.bh-nav[href='/hub/alpha/flagged']"
    assert_select "a.bh-nav[href='/hub/beta/proposal/new']"
  end

  test "sections are hidden from people who may not use them" do
    sign_in_as "staff"
    get "/hub/beta"
    assert_select ".bh-group-label", text: "Beta · config"
    assert_select ".bh-group-label", text: "Alpha · audit", count: 0
  end

  test "badges show only when they have something to say, and a broken one is skipped" do
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select "a.bh-nav[href='/hub/alpha'] .bh-badge", "3"
    assert_select "a.bh-nav[href='/hub/alpha/rules'] .bh-badge", count: 0
    assert_select "a.bh-nav[href='/hub/beta/broken']"
    assert_select "a.bh-nav[href='/hub/beta/broken'] .bh-badge", count: 0
  end

  test "the current page is highlighted" do
    sign_in_as "auditor"
    get "/hub/alpha/flagged"
    assert_select "a.bh-nav.is-active", count: 1
    assert_select "a.bh-nav.is-active[href='/hub/alpha/flagged']"

    get "/hub/alpha"
    assert_select "a.bh-nav.is-active[href='/hub/alpha']"
    assert_select "a.bh-nav.is-active", count: 1
  end

  test "an engine mounted on its own shows just its own section" do
    sign_in_as "staff"
    get "/solo/other"
    assert_response :success
    assert_select ".bh-group-label", text: "Gamma · solo"
    assert_select ".bh-group-label", count: 1
    assert_select "a.bh-nav[href='/solo']"
    assert_select "a.bh-nav.is-active[href='/solo/other']"
  end

  test "a section the hub does not mount is not linked from the hub" do
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select ".bh-group-label", text: "Gamma · solo", count: 0
  end

  test "sidebar items can be hidden per person" do
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select "a.bh-nav[href='/hub/alpha/unlocks']"
    assert_select "a.bh-nav[href='/hub/alpha/admin-only']", count: 0
  end

  test "an engine mounted at a path that looks like the hub is not treated as inside it" do
    sign_in_as "auditor"
    get "/gamma/other"
    assert_response :success
    assert_select ".bh-group-label", count: 1
    assert_select ".bh-group-label", text: "Gamma · solo"
  end

  test "the hero can colour its subtitle" do
    sign_in_as "auditor"
    get "/hub/alpha/sessions"
    assert_select ".bh-title-sub.bh-tone-green", false
    get "/hub/beta/tone"
    assert_select ".bh-title-sub.bh-tone-green", "page"
  end

  test "accent colours come through as custom properties" do
    sign_in_as "auditor"
    get "/hub/alpha"
    assert_select ".bh-group[style*='#f04f54']"
    assert_select ".bh-group[style*='#2ecc7a']"
  end

  test "the shell sends pages that must not be cached with no-store" do
    sign_in_as "auditor"
    get "/hub"
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "the hub refuses plain HTTP when require_ssl is on" do
    with_config(require_ssl: true) do
      sign_in_as "auditor"
      get "/hub"
      assert_response :forbidden
    end
  end
end
