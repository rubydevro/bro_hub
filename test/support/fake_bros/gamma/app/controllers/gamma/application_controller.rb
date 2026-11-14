module Gamma
  class ApplicationController < ::ApplicationController
    include BroHub::Layout
    bro_hub_section :gamma
  end
end
