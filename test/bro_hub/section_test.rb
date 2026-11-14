require "test_helper"

class BroHub::SectionTest < ActiveSupport::TestCase
  def section(**options)
    BroHub::Section.new(:demo, label: "Demo · things", items: [ { label: "Home", path: "/" } ], **options)
  end

  test "name defaults to the label up to the dot" do
    assert_equal "Demo", section.name
    assert_equal "Short", section(name: "Short").name
  end

  test "accepts named accents and hex colours" do
    assert_equal "#f04f54", section(accent: :red).accent
    assert_equal "#abc123", section(accent: "#abc123").accent
  end

  test "rejects anything else as an accent, since it ends up in a style attribute" do
    assert_raises(ArgumentError) { section(accent: "red; background: url(x)") }
    assert_raises(ArgumentError) { section(accent: :nope) }
  end

  test "needs at least one item" do
    assert_raises(ArgumentError) { BroHub::Section.new(:x, label: "X", items: []) }
  end

  test "visibility defaults to any signed-in person, never to nobody" do
    assert section.visible_to?(Object.new)
    assert_not section.visible_to?(nil)
    assert_not section(visible_to: ->(_) { false }).visible_to?(Object.new)
    assert_not section(visible_to: ->(_) { true }).visible_to?(nil)
  end

  test "engine can be given as a class name" do
    assert_equal BroHub::Engine, section(engine: "BroHub::Engine").engine
  end

  test "item matching" do
    root, other = BroHub::Section.new(:demo, label: "D", items: [ { label: "a", path: "/" }, { label: "b", path: "/flagged" } ]).items
    assert root.active?("/")
    assert_not root.active?("/flagged")
    assert other.active?("/flagged")
    assert other.active?("/flagged/3")
    assert_not other.active?("/flaggedx")
  end

  test "an explicit match overrides the default" do
    item = BroHub::Section.new(:demo, label: "D", items: [ { label: "a", path: "/", match: %r{\A/(sessions|\z)} } ]).items.first
    assert item.active?("/sessions/4")
    assert item.active?("/")
    assert_not item.active?("/rules")
  end

  test "badge values" do
    items = BroHub::Section.new(:demo, label: "D", items: [
      { label: "n", path: "/", badge: -> { 5 } }, { label: "z", path: "/z", badge: -> { 0 } },
      { label: "nil", path: "/n", badge: -> { nil } }, { label: "static", path: "/s", badge: "new" }
    ]).items
    assert_equal [ 5, nil, nil, "new" ], items.map(&:badge_value)
  end
end

class BroHub::RegistryTest < ActiveSupport::TestCase
  setup { @registry = BroHub::Registry.new }

  def add(key, order: 100, visible: true)
    @registry.register BroHub::Section.new(key, label: key.to_s, order: order, visible_to: ->(_) { visible }, items: [ { label: "x", path: "/" } ])
  end

  test "sorts by order, then registration" do
    add :c, order: 20
    add :a, order: 10
    add :b, order: 10
    assert_equal %i[ a b c ], @registry.map(&:key)
  end

  test "registering a key again replaces it" do
    add :a
    add :a, order: 5
    assert_equal 1, @registry.count
  end

  test "visible_to filters" do
    add :a
    add :b, visible: false
    assert_equal %i[ a ], @registry.visible_to(Object.new).map(&:key)
    assert_empty @registry.visible_to(nil)
  end
end
