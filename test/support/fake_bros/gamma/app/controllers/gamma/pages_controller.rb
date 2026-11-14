module Gamma
  class PagesController < ApplicationController
    def show
      @page = params[:page].presence || "home"
    end
  end
end
