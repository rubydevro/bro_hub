Gamma::Engine.routes.draw do
  root "pages#show"
  get "*page" => "pages#show", as: :page
end
