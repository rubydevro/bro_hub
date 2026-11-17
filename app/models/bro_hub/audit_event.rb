module BroHub
  # Who did what, in any Bro gem. Append-only: a saved row can't be changed.
  #
  # Gems write rows with BroHub::Audit.record and read their own through a small subclass that sets `source`:
  #
  #   class CacheBro::AuditEvent < BroHub::AuditEvent
  #     default_scope { where(source: "cache_bro") }
  #   end
  class AuditEvent < ApplicationRecord
    # The subclasses share this table and are told apart by `source`, not by a type column.
    self.inheritance_column = nil

    # The column has no database default (MySQL refuses one on JSON), so the model supplies it.
    attribute :details, default: -> { {} }

    belongs_to :parent, class_name: "BroHub::AuditEvent", optional: true

    validates :source, :event, :environment, presence: true

    scope :recent, -> { order(created_at: :desc, id: :desc) }
    scope :from_source, ->(source) { where(source: source.to_s) }

    def readonly?
      persisted? || super
    end

    # A sample of what a bulk action touched (see each gem's audit_sample_size).
    def sample
      Array(details["sample"])
    end

    def truncated?
      details["truncated"] == true
    end

    def section
      BroHub.registry[source]
    end

    def source_name
      section&.name || source.to_s.humanize
    end
  end
end
