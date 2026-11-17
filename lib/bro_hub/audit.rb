module BroHub
  # The one place every Bro gem writes its audit trail.
  #
  #   BroHub::Audit.record(source: :cache_bro, event: :keys_purged, user: "jane@example.com",
  #     context: "Rails.cache", target: "posts/*", count: 12, reason: "stale", sample: [ "posts/1" ])
  #
  # Never put secrets in it: keys, patterns and names, never values. It fails closed: when the row can't be
  # written the error is logged and raised, so a caller that must not act unaudited (revealing a value) stops.
  module Audit
    module_function

    # user:    a String is stored as it is (a label, or a system actor like "deploy"). Anything else goes through
    #          BroHub.config.user_label. A gem with its own user_label turns the user into a String first.
    # model:   BroHub::AuditEvent, or a gem's own subclass when it validates its events.
    # columns: raw attributes for the few things the named arguments don't cover (a gem's own link to another row).
    # details: anything else, saved as JSON.
    def record(source:, event:, user:, model: BroHub::AuditEvent, context: nil, target: nil, count: nil, reason: nil, ip: nil,
               reference: nil, digest: nil, parent: nil, columns: {}, **details)
      attributes = {
        source: source.to_s,
        event: event.to_s,
        user_label: user.is_a?(String) ? user : BroHub.config.user_label.call(user).to_s,
        environment: Rails.env.to_s,
        context: context.presence&.to_s,
        target: target,
        count: count,
        reason: reason.presence,
        ip: ip.presence,
        reference: reference,
        digest: digest,
        parent: parent,
        details: details.deep_stringify_keys
      }.merge(columns)
      model.create!(**attributes)
    rescue StandardError => error
      # The action already happened (or, for a reveal, is about to be refused): at least leave a trace in the log.
      Rails.logger&.error("BroHub: could not write the audit log (#{error.class}: #{error.message}). Entry: #{attributes.inspect}")
      raise
    end

    # False until the migration has run: lets a gem show "run db:migrate" instead of an error page.
    def ready?
      BroHub::AuditEvent.table_exists?
    rescue ActiveRecord::ActiveRecordError
      false
    end
  end
end
