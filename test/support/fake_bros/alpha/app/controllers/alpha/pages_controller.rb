module Alpha
  class PagesController < ApplicationController
    def show
      @page = params[:page].presence || "home"
      render :sessions if @page == "sessions"
      render :detail if @page == "sessions/5"
    end
  end
end
