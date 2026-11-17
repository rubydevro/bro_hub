module BroHub
  module ApplicationHelper
    # The mount point of the hub, without a trailing slash ("" when mounted at "/"), or nil when this page is
    # not served through the hub (a Bro gem the host mounted on its own). The hub records its mount point in the
    # request as it hands over to an engine, so a gem mounted at a path that merely looks like "<hub>/<key>"
    # is not mistaken for one.
    def bro_hub_root
      return @bro_hub_root if defined?(@bro_hub_root)

      @bro_hub_root =
        if request.env["bro_hub.root"] then request.env["bro_hub.root"]
        elsif controller.try(:bro_hub_section_key).nil? then request.script_name.to_s.delete_suffix("/")
        end
    end

    # The sidebar: [ [section, base_path, current?], ... ] for what this person may see.
    def bro_hub_sections
      @bro_hub_sections ||= begin
        user = bro_hub_user
        current_key = controller.try(:bro_hub_section_key)
        sections = BroHub.registry.visible_to(user)
        # We can only link to what lives under the hub (it mounts the engines) or to the page we are on.
        # A section whose engine the host mounted elsewhere shows up inside its own pages only.
        sections = sections.select { |section| section.key == current_key || (bro_hub_root && section.engine) }
        sections.map do |section|
          base = bro_hub_root ? "#{bro_hub_root}/#{section.key}" : request.script_name.to_s.delete_suffix("/")
          [ section, base, section.key == current_key ]
        end
      end
    end

    def bro_hub_current_section
      BroHub.registry[controller.try(:bro_hub_section_key)]
    end

    def bro_hub_link_path(base, item)
      path = "#{base}#{item.path.to_s == "/" ? "" : "/" + item.path.to_s.delete_prefix("/")}"
      path.presence || "/"
    end

    def bro_hub_item_active?(section_current, base, item)
      return false unless section_current

      item.active?(request.path.delete_prefix(base))
    end

    def bro_hub_user_label
      user = bro_hub_user
      BroHub.config.user_label.call(user) if user
    end

    def bro_hub_page_title
      parts = [ content_for(:bro_hub_title).presence, bro_hub_current_section&.name, "Bro Hub" ].compact
      parts.uniq.join(" · ")
    end

    # Breadcrumb after the section name: bro_hub_crumb "Console sessions", "#5"
    def bro_hub_crumb(*parts)
      content_for(:bro_hub_crumb, parts.join(" / "), flush: true)
      content_for(:bro_hub_title, parts.last.to_s, flush: true)
      nil
    end

    # Links on the right of the breadcrumb bar (filters, "back", environment tabs).
    def bro_hub_crumb_link(label, href, active: false)
      link_to label, href, class: [ "bh-tab", ("is-active" if active) ]
    end

    # The big page heading.
    #   bro_hub_hero eyebrow: "Console sessions · production", title: "3", subtitle: "awaiting a verdict",
    #                tone: :red, subtitle_tone: :green, lead: "Who used a production console...", stats: [ [ 4, "unlocks", :amber ] ]
    def bro_hub_hero(eyebrow: nil, title:, subtitle: nil, tone: nil, subtitle_tone: nil, lead: nil, stats: [], &block)
      render "bro_hub/shared/hero", eyebrow: eyebrow, title: title, subtitle: subtitle, tone: tone, subtitle_tone: subtitle_tone, lead: lead,
        stats: stats, extra: (capture(&block) if block)
    end

    # "2026-11-16 09:30", in UTC, with the exact time on hover.
    def bro_hub_time(time)
      return "-" unless time

      content_tag(:time, time.utc.strftime("%Y-%m-%d %H:%M"), datetime: time.iso8601, title: time.utc.to_s)
    end

    # What the sidebar's own "Bro Hub" group links to: [ label, path, active? ] for this person, or none.
    def bro_hub_own_items
      return [] unless bro_hub_root && bro_hub_user && BroHub.registry.audited_by(bro_hub_user).any?

      [ [ "Audit log", "#{bro_hub_root}/audit", request.path.start_with?("#{bro_hub_root}/audit") && controller.try(:bro_hub_section_key).nil? ] ]
    end

    # "← Newer / Older →" for any list paged by a `page` param, counted from 0.
    def bro_hub_pager(total:, page:, per_page:, noun: "event")
      newer = link_to("← Newer", url_for(request.query_parameters.merge(page: page - 1))) if page > 0
      older = link_to("Older →", url_for(request.query_parameters.merge(page: page + 1))) if (page + 1) * per_page < total
      content_tag(:div, class: "bh-meta", style: "display:flex;justify-content:space-between;gap:16px;margin-top:14px") do
        safe_join([ content_tag(:span, "#{number_with_delimiter(total)} #{total == 1 ? noun : noun.pluralize}"),
                    content_tag(:span, safe_join([ newer, older ].compact, " ")) ])
      end
    end

    # Inline <style> that works under a nonce-based Content Security Policy.
    def bro_hub_style_tag
      tag.style(BroHub.styles.html_safe, nonce: (content_security_policy_nonce if respond_to?(:content_security_policy_nonce)))
    end
  end
end
