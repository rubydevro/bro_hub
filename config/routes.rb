BroHub::Engine.routes.draw do
  root "home#index"

  # Every registered engine lives under the hub: /<mount>/<section key>/...
  BroHub.registry.each do |section|
    mount section.engine => "/#{section.key}", as: section.key if section.engine
  end
end
