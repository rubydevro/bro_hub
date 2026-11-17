BroHub::Engine.routes.draw do
  root "home#index"

  # Before the sections, so a gem can never shadow them.
  get "audit", to: "audit_events#index", as: :audit
  get "audit/:id", to: "audit_events#show", as: :audit_event

  # Every registered engine lives under the hub: /<mount>/<section key>/...
  BroHub.registry.each do |section|
    mount section.engine => "/#{section.key}", as: section.key if section.engine
  end
end
