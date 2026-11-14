module BroHub
  class Engine < ::Rails::Engine
    isolate_namespace BroHub

    middleware.use BroHub::RootMiddleware
  end
end
