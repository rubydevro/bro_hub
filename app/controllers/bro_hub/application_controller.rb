module BroHub
  class ApplicationController < BroHub.config.parent_controller.constantize
    include BroHub::ControllerBase

    before_action :bro_hub_require_ssl
    before_action :bro_hub_no_store

    private
      def bro_hub_require_ssl
        head :forbidden if BroHub.config.require_ssl && !request.ssl?
      end

      def bro_hub_no_store
        response.headers["Cache-Control"] = "no-store"
        response.headers["Pragma"] = "no-cache"
      end
  end
end
