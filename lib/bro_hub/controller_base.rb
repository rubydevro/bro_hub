module BroHub
  # Include in every Bro controller base (BroHub's own, and each gem's ApplicationController). It holds
  # what must be right for *any* host app, so a clash with the host's ApplicationController is fixed once, here:
  #
  #   class SafeBro::ApplicationController < SafeBro.config.parent_controller.constantize
  #     include BroHub::ControllerBase
  #     bro_hub_section :safe_bro
  module ControllerBase
    extend ActiveSupport::Concern

    included do
      include BroHub::Layout

      protect_from_forgery with: :exception

      # The host's Pundit checks (`after_action :verify_authorized`) don't apply: Bro controllers authorize
      # people themselves and have no policy to ask. No-ops when Pundit isn't in use.
      skip_after_action :verify_authorized, raise: false
      skip_after_action :verify_policy_scoped, raise: false
    end
  end
end
