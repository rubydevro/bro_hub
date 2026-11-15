require "bro_hub/version"
require "bro_hub/configuration"
require "bro_hub/section"
require "bro_hub/registry"
require "bro_hub/layout"
require "bro_hub/controller_base"
require "bro_hub/root_middleware"
require "bro_hub/engine"

# The shared admin shell for the Bro gems.
#
#   BroHub.register :safe_bro, name: "SafeBro", label: "SafeBro · audit", accent: :red,
#     engine: "SafeBro::Engine",
#     items: [ { label: "Sessions", path: "/", badge: -> { SafeBro::Session.pending.count } } ],
#     visible_to: ->(user) { SafeBro.config.can_audit.call(user) }
module BroHub
  SKULL_PATH = File.expand_path("bro_hub/skull.png", __dir__)
  STYLES_PATH = File.expand_path("bro_hub/styles.css", __dir__)

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def registry
      @registry ||= Registry.new
    end

    # Adds (or replaces) a section in the sidebar. See Section for the options.
    def register(key, **options)
      registry.register(Section.new(key, **options))
    end

    def skull_data_uri
      @skull_data_uri ||= "data:image/png;base64,#{[ File.binread(SKULL_PATH) ].pack("m0")}"
    end

    def styles
      @styles ||= File.read(STYLES_PATH)
    end
  end
end
