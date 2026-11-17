# One audit table for every Bro gem. Each gem writes its own rows (the `source` column) through BroHub::Audit.
class CreateBroHubAuditEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :bro_hub_audit_events do |t|
      # The gem that wrote the row ("env_bro", "safe_bro", "cache_bro") and what happened.
      t.string :source, null: false
      t.string :event, null: false
      t.string :user_label
      t.string :environment, null: false
      # Where it happened, when that is a thing: a cache store name, a console host.
      t.string :context
      # What it happened to: a key, a key pattern, a session.
      t.text :target
      t.integer :count
      t.text :reason
      t.string :ip
      # Lookups for gems that link rows together: EnvBro keeps a proposal's token and the digest of its file here.
      t.string :reference
      t.string :digest
      t.references :parent, foreign_key: { to_table: :bro_hub_audit_events }, index: false
      # No column default: MySQL rejects defaults on JSON columns. BroHub::Audit.record always sets it.
      t.json :details, null: false
      t.datetime :created_at, null: false
    end

    add_index :bro_hub_audit_events, :created_at
    add_index :bro_hub_audit_events, [ :source, :created_at ]
    add_index :bro_hub_audit_events, [ :source, :event, :created_at ]
    add_index :bro_hub_audit_events, [ :user_label, :created_at ]
    add_index :bro_hub_audit_events, :reference
    add_index :bro_hub_audit_events, :digest
    # A row can have one follow-up of each kind (one deployment per proposal).
    add_index :bro_hub_audit_events, [ :parent_id, :event ], unique: true
  end
end
