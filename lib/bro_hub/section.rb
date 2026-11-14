module BroHub
  # One block of the sidebar, owned by one gem.
  class Section
    ACCENTS = {
      red: "#f04f54", green: "#2ecc7a", violet: "#7c6dfa", amber: "#f5b84a", blue: "#4aa8f5"
    }.freeze

    Item = Struct.new(:label, :path, :badge, :match, :visible_to, keyword_init: true) do
      def visible_to?(user)
        visible_to ? !!visible_to.call(user) : true
      end

      # The badge is computed on every page: a broken one must never take the shell down.
      def badge_value
        value = badge.respond_to?(:call) ? badge.call : badge
        value.presence if value.to_s != "0"
      rescue StandardError => error
        Rails.logger.warn("BroHub: badge for #{label.inspect} failed: #{error.class}: #{error.message}") if defined?(Rails)
        nil
      end

      # path is relative to the section, so "/flagged" and "" are both fine.
      def active?(relative_path)
        relative_path = normalize(relative_path)
        if match
          match.match?(relative_path)
        elsif normalize(path) == "/"
          relative_path == "/"
        else
          relative_path == normalize(path) || relative_path.start_with?("#{normalize(path)}/")
        end
      end

      private
        def normalize(value)
          "/" + value.to_s.delete_prefix("/").delete_suffix("/")
        end
    end

    attr_reader :key, :name, :label, :accent, :items, :order

    # key:        :safe_bro. Also the URL segment the engine is mounted under.
    # name:       short name for the breadcrumb ("SafeBro"). Defaults to the label up to the first "·".
    # label:      sidebar heading ("SafeBro · audit").
    # accent:     :red, :green, :violet, :amber, :blue, or a hex colour.
    # engine:     the Rails engine (class or class name) BroHub mounts under /<key>. Leave out if the host mounts it.
    # items:      [ { label:, path:, badge: (callable), match: (Regexp on the section-relative path),
    #               visible_to: ->(user) { true } } ]
    # visible_to: ->(user) { true } decides whether this person sees the section. Navigation only, not security:
    #             every engine still authorizes its own pages.
    # order:      lower comes first.
    def initialize(key, label:, items:, name: nil, accent: :violet, engine: nil, visible_to: nil, order: 100)
      @key = key.to_sym
      @label = label.to_s
      @name = (name || @label.split("·").first).to_s.strip
      @accent = resolve_accent(accent)
      @engine = engine
      @visible_to = visible_to
      @order = order
      @items = Array(items).map { |item| Item.new(**item.symbolize_keys.slice(:label, :path, :badge, :match, :visible_to)) }
      raise ArgumentError, "BroHub section #{key} needs at least one item" if @items.empty?
    end

    def engine
      @engine.is_a?(String) ? @engine.constantize : @engine
    end

    def visible_to?(user)
      return false unless user

      @visible_to ? !!@visible_to.call(user) : true
    end

    def visible_items(user)
      items.select { |item| item.visible_to?(user) }
    end

    # Where to send someone who opens the section: its first item they may see.
    def first_path(user = nil)
      (user ? visible_items(user).first : items.first)&.path || items.first.path
    end

    private
      def resolve_accent(accent)
        return ACCENTS.fetch(accent) { raise ArgumentError, "unknown accent #{accent.inspect}, use one of #{ACCENTS.keys.inspect}" } if accent.is_a?(Symbol)
        # The colour ends up in a style attribute, so only a plain hex colour is accepted.
        return accent if accent.to_s.match?(/\A#\h{3,8}\z/)

        raise ArgumentError, "accent must be one of #{ACCENTS.keys.inspect} or a hex colour like #7c6dfa"
      end
  end
end
