require "rails/generators"

module BroHub
  module Generators
    # bin/rails generate bro_hub:install
    #
    # Mounts the dashboard and installs every Bro gem in the bundle (the ones that registered a section).
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Mounts the BroHub dashboard and runs the installer of each Bro gem in your bundle."

      DEFAULT_MOUNT_PATH = "/bro_hub"

      class_option :mount_path, type: :string,
        desc: "Where to mount the dashboard (asked interactively when omitted, default #{DEFAULT_MOUNT_PATH})"
      class_option :install_gems, type: :boolean, default: true, hide: true,
        desc: "Also run the installers of the Bro gems in the bundle"
      class_option :remove_direct_mounts, type: :boolean, default: nil,
        desc: "Comment out old `mount SafeBro::Engine`-style lines (asked interactively when omitted)"

      # Bro gems that only work with BroHub from these versions on.
      MINIMUM_VERSIONS = { "env_bro" => "0.2.0", "safe_bro" => "0.1.0" }.freeze

      def check_gem_versions
        MINIMUM_VERSIONS.each do |name, minimum|
          installed = Gem.loaded_specs[name]&.version
          next if installed.nil? || installed >= Gem::Version.new(minimum)

          say_status :warning, "#{name} #{installed} is too old for BroHub (needs #{minimum}+), so it is not installed " \
            "and its old mount is left alone. Run `bundle update #{name}` and install again.", :red
        end
      end

      def copy_initializer
        if File.exist?(File.join(destination_root, "config/initializers/bro_hub.rb"))
          say_status :skip, "config/initializers/bro_hub.rb already exists, leaving it alone", :yellow
        else
          copy_file "bro_hub.rb", "config/initializers/bro_hub.rb"
        end
      end

      # The one audit table every Bro gem writes to. Copied once: running the installer again skips it.
      def copy_migrations
        rails_command "bro_hub:install:migrations", inline: true
      end

      def mount_engine
        if routes_source.include?("BroHub::Engine")
          say_status :skip, "BroHub::Engine is already mounted", :yellow
        else
          route %(mount BroHub::Engine => "#{mount_path}")
        end
      end

      # A gem mounted directly *and* under the hub would be served twice.
      def retire_direct_mounts
        direct_mounts.each do |line|
          if remove_direct_mount?(line)
            indent = line[/\A\s*/]
            gsub_file "config/routes.rb", line, "#{indent}# BroHub mounts this now: #{line.strip}"
          else
            say_status :warning, "#{line.strip} is still mounted directly; BroHub also serves it under #{mount_path}. " \
              "Re-run with --remove-direct-mounts or delete the line.", :yellow
          end
        end
      end

      def install_bro_gems
        return unless options[:install_gems]

        bro_gem_installers.each do |section, namespace|
          say_status :install, "#{section.name} (#{namespace})", :green
          invoke namespace, [], { skip_bro_hub: true, mount_path: mount_path }.merge(conflict_options)
        end
      end

      def next_steps
        say <<~TEXT

          BroHub is installed. Next:
            1. bin/rails db:migrate (creates the audit table all the Bro gems share)
            2. Check config/initializers/bro_hub.rb (how to find the signed-in user)
            3. Visit #{mount_path}. Each Bro gem lives under #{mount_path}/<gem>, the combined audit log under #{mount_path}/audit
        TEXT
      end

      private
        # Pass --skip/--force/--pretend/--quiet on to the installers of the other gems.
        def conflict_options
          options.slice(:force, :skip, :pretend, :quiet).to_h.symbolize_keys.select { |_, value| value }
        end

        def routes_source
          path = File.join(destination_root, "config/routes.rb")
          File.exist?(path) ? File.read(path) : ""
        end

        def mount_path
          @mount_path ||= begin
            path = options[:mount_path].presence
            path ||= existing_mount_path
            path ||= ask("Where should the dashboard be mounted?", default: DEFAULT_MOUNT_PATH) if $stdin.tty?
            path = path.to_s.strip.presence || DEFAULT_MOUNT_PATH
            "/" + path.delete_prefix("/").delete_suffix("/")
          end
        end

        def existing_mount_path
          routes_source[/mount BroHub::Engine => "([^"]+)"/, 1]
        end

        # Routes that mount an engine BroHub now mounts itself.
        def direct_mounts
          engines = BroHub.registry.filter_map { |section| section.engine&.name }
          routes_source.lines.map(&:chomp).select do |line|
            !line.strip.start_with?("#") && engines.any? { |name| line.match?(/\A\s*mount\s+#{Regexp.escape(name)}\b/) }
          end
        end

        def remove_direct_mount?(line)
          return options[:remove_direct_mounts] unless options[:remove_direct_mounts].nil?

          $stdin.tty? && yes?("#{line.strip} is now mounted by BroHub. Comment it out? (y/N)")
        end

        # [ [ section, "safe_bro:install" ], ... ] for the registered gems that ship an installer.
        def bro_gem_installers
          BroHub.registry.filter_map do |section|
            namespace = "#{section.key}:install"
            [ section, namespace ] if section.engine && Rails::Generators.find_by_namespace(namespace)
          end
        end
    end
  end
end
