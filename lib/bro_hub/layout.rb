module BroHub
  # Include in a Bro gem's controller to render inside the shared shell:
  #
  #   class SafeBro::ApplicationController < ...
  #     include BroHub::Layout
  #     bro_hub_section :safe_bro
  module Layout
    extend ActiveSupport::Concern

    included do
      class_attribute :bro_hub_section_key, instance_writer: false
      layout "bro_hub/application"
      helper BroHub::ApplicationHelper
      helper_method :bro_hub_user, :bro_hub_section_key
    end

    class_methods do
      def bro_hub_section(key)
        self.bro_hub_section_key = key.to_sym
      end
    end

    private
      # Override when the gem has its own idea of who is signed in.
      def bro_hub_user
        return @bro_hub_user if defined?(@bro_hub_user)

        @bro_hub_user = BroHub.config.current_user.call(self)
      end
  end
end
