require "generators/bro_hub/installable"

module Alpha
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include BroHub::Generators::Installable

      def write_marker
        create_file "config/alpha_installed.txt", "alpha\n"
      end
    end
  end
end
