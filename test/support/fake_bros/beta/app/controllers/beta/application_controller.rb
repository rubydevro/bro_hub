module Beta
  class ApplicationController < ::ApplicationController
    include BroHub::Layout
    bro_hub_section :beta
  end
end
