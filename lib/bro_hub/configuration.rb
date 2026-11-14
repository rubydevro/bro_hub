module BroHub
  class Configuration
    # Controller the shell's own pages inherit from, so the host's authentication runs.
    attr_accessor :parent_controller

    # ->(controller) { the signed-in user, or nil }. The default calls `current_user` when the controller has it.
    attr_accessor :current_user

    # ->(user) { text shown at the top right }
    attr_accessor :user_label

    # Refuse the shell's own pages over plain HTTP. Each Bro gem decides this for its own pages.
    attr_accessor :require_ssl

    attr_accessor :brand_name, :brand_url

    def initialize
      @parent_controller = "::ApplicationController"
      @current_user = ->(controller) { controller.send(:current_user) if controller.respond_to?(:current_user, true) }
      @user_label = ->(user) { user.try(:email) || user.try(:name) || user.to_s }
      @require_ssl = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env.production? : false
      @brand_name = "DeadBro"
      @brand_url = "https://www.deadbro.com"
    end
  end
end
