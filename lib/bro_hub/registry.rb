module BroHub
  class Registry
    include Enumerable

    def initialize
      @sections = {}
    end

    def register(section)
      @sections[section.key] = section
    end

    def [](key)
      @sections[key&.to_sym]
    end

    def each(&block)
      sorted.each(&block)
    end

    def visible_to(user)
      select { |section| section.visible_to?(user) }
    end

    def clear
      @sections.clear
    end

    private
      def sorted
        @sections.values.each_with_index.sort_by { |section, index| [ section.order, index ] }.map(&:first)
      end
  end
end
