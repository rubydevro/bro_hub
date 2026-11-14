module BroHub
  class HomeController < ApplicationController
    # The hub itself has no page: send people to the first section they may use.
    def index
      section = BroHub.registry.visible_to(bro_hub_user).first
      return render("bro_hub/shared/forbidden", status: :forbidden) unless section

      path = section.first_path(bro_hub_user).to_s
      redirect_to "#{request.script_name.delete_suffix("/")}/#{section.key}#{path == "/" ? "" : "/" + path.delete_prefix("/")}"
    end
  end
end
