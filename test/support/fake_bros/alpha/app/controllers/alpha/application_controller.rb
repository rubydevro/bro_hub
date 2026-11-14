module Alpha
  class ApplicationController < ::ApplicationController
    include BroHub::Layout
    bro_hub_section :alpha
  end
end
