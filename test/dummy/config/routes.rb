Rails.application.routes.draw do
  root "home#index"
  post "role" => "home#role", as: :role

  mount BroHub::Engine => "/hub"
  # Mounted on its own, outside the hub.
  mount Gamma::Engine => "/solo"
  # Mounted at a path that looks like <hub>/<key> but is not the hub.
  mount Gamma::Engine => "/gamma", as: :gamma_lookalike
end
