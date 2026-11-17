BroHub.register :alpha, label: "Alpha · audit", accent: :red, engine: "Alpha::Engine", order: 10,
  visible_to: ->(user) { user.can?(:audit) },
  audit_visible_to: ->(user) { user.can?(:audit) },
  items: [
    { label: "Sessions", path: "/", badge: -> { 3 } },
    { label: "Flagged commands", path: "/flagged" },
    { label: "Unlocks", path: "/unlocks" },
    { label: "Admin only", path: "/admin-only", visible_to: ->(user) { user.role == "admin" } },
    { label: "Rules", path: "/rules", badge: -> { 0 } }
  ]

BroHub.register :beta, label: "Beta · config", accent: :green, engine: "Beta::Engine", order: 20,
  audit_visible_to: ->(user) { user.role == "staff" },
  items: [
    { label: "Environments", path: "/" },
    { label: "Propose a change", path: "/proposal/new" },
    { label: "Broken badge", path: "/broken", badge: -> { raise "boom" } }
  ]

# Not mounted by the hub: the host mounts it at /solo.
BroHub.register :gamma, label: "Gamma · solo", accent: "#4aa8f5", order: 30,
  items: [ { label: "Overview", path: "/" }, { label: "Other", path: "/other" } ]
