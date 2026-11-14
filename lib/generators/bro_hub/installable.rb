require "rails/generators"
require "generators/bro_hub/install/install_generator"

module BroHub
  module Generators
    # The rule for a Bro gem's own installer: set up BroHub first, then yourself.
    #
    #   class SafeBro::Generators::InstallGenerator < Rails::Generators::Base
    #     include BroHub::Generators::Installable   # first line, so BroHub's step runs first
    #
    #     def copy_initializer ... end
    #   end
    #
    # `rails g safe_bro:install` then mounts BroHub (once, whatever else is installed) and installs SafeBro.
    # `rails g bro_hub:install` installs every Bro gem in the bundle by running their installers with
    # --skip-bro-hub, since it has just done that step itself.
    module Installable
      extend ActiveSupport::Concern

      included do
        class_option :mount_path, type: :string,
          desc: "Where to mount the BroHub dashboard (asked interactively when omitted, default #{BroHub::Generators::InstallGenerator::DEFAULT_MOUNT_PATH})"
        class_option :remove_direct_mounts, type: :boolean, default: nil,
          desc: "Comment out old `mount SafeBro::Engine`-style lines, since BroHub mounts the gems itself"
        class_option :skip_bro_hub, type: :boolean, default: false, hide: true,
          desc: "BroHub is already set up (used by bro_hub:install)"

        # Defined here, not in the module body, so Thor registers it as the first command of the generator.
        def install_bro_hub
          return if options[:skip_bro_hub]

          forward = { install_gems: false }
          forward[:mount_path] = options[:mount_path] if options[:mount_path].present?
          forward[:remove_direct_mounts] = options[:remove_direct_mounts] unless options[:remove_direct_mounts].nil?
          invoke "bro_hub:install", [], forward
        end
      end

      private
        # Where BroHub ended up, read back from the routes (it may have been mounted before).
        def bro_hub_path
          routes = File.join(destination_root, "config/routes.rb")
          mounted = File.read(routes)[/mount BroHub::Engine => "([^"]+)"/, 1] if File.exist?(routes)
          mounted || BroHub::Generators::InstallGenerator::DEFAULT_MOUNT_PATH
        end
    end
  end
end
