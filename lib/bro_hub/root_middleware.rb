module BroHub
  # Runs as the hub's engine is called, when SCRIPT_NAME is still the hub's own mount point.
  # Engines mounted under the hub (and the shell's layout) read it from here.
  class RootMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      env["bro_hub.root"] ||= env["SCRIPT_NAME"].to_s.delete_suffix("/")
      response = @app.call(env)
      # Nothing here matched and the host router will try its next route: this was not a hub request after all.
      env.delete("bro_hub.root") if response[1]["X-Cascade"] == "pass"
      response
    end
  end
end
