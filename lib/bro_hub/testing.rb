require "bro_hub"

module BroHub
  # For the test suites of Bro gems (and apps): creates the audit table in the test database.
  #
  #   # test_helper.rb, after loading the Rails environment
  #   require "bro_hub/testing"
  #   BroHub::Testing.load_schema
  module Testing
    MIGRATION = File.expand_path("../../db/migrate/20261116000000_create_bro_hub_audit_events.rb", __dir__)

    # What BroHub's installer would have run (`rails_command`), once record_rails_commands is on.
    RAILS_COMMANDS = []

    module RecordRailsCommands
      def rails_command(command, *)
        RAILS_COMMANDS << command
      end
    end

    module_function

    # For generator tests: BroHub's installer copies its migration with `bin/rails`, which an empty test app
    # doesn't have. Call this once and read what it would have run from BroHub::Testing::RAILS_COMMANDS.
    def record_rails_commands
      require "generators/bro_hub/install/install_generator"
      generator = BroHub::Generators::InstallGenerator
      generator.prepend(RecordRailsCommands) unless generator < RecordRailsCommands
      RAILS_COMMANDS
    end

    # Always rebuilds the table, so a stale one from an older version can't linger.
    def load_schema
      verbose = ActiveRecord::Migration.verbose
      load MIGRATION unless defined?(::CreateBroHubAuditEvents)
      ActiveRecord::Migration.verbose = false
      connection = ActiveRecord::Base.connection
      connection.drop_table(:bro_hub_audit_events, if_exists: true)
      ::CreateBroHubAuditEvents.new.migrate(:up)
      BroHub::AuditEvent.reset_column_information
    ensure
      ActiveRecord::Migration.verbose = verbose
    end
  end
end
