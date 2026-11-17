module BroHub
  # The audit trail of every Bro gem in one place. Each person sees the rows of the gems they may audit.
  class AuditEventsController < ApplicationController
    PER_PAGE = 50

    before_action :require_auditor
    helper_method :filter_params, :sections

    def index
      @filter = filter_params
      @events = filtered.recent.limit(PER_PAGE).offset(page * PER_PAGE)
      @total = filtered.count
      @page = page
      @counts = visible.group(:source).count
      @event_names = visible.distinct.order(:event).pluck(:event)
    end

    def show
      @event = visible.find(params[:id])
    end

    private
      def require_auditor
        render "bro_hub/shared/forbidden", status: :forbidden if sections.empty?
      end

      def sections
        @sections ||= BroHub.registry.audited_by(bro_hub_user)
      end

      # Only the rows of gems this person may audit, and only the ones still installed.
      def visible
        AuditEvent.where(source: sections.map { |section| section.key.to_s })
      end

      def filtered
        scope = visible
        scope = scope.where(source: filter_params[:source]) if filter_params[:source].present?
        scope = scope.where(event: filter_params[:event]) if filter_params[:event].present?
        scope = scope.where(user_label: filter_params[:user]) if filter_params[:user].present?
        if filter_params[:q].present?
          like = "%#{AuditEvent.sanitize_sql_like(filter_params[:q])}%"
          scope = scope.where("target LIKE :like OR reason LIKE :like", like: like)
        end
        scope
      end

      def filter_params
        @filter_params ||= params.permit(:source, :event, :user, :q).to_h.symbolize_keys.compact_blank
      end

      def page
        [ params[:page].to_i, 0 ].max
      end
  end
end
