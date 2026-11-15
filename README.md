# BroHub

One dashboard shell for the Bro gems ([EnvBro](https://github.com/rubydevro/env_bro), [SafeBro](https://github.com/rubydevro/safe_bro), and whatever comes next).

- **One mount point.** `/bro_hub/safe_bro`, `/bro_hub/env_bro`, ... BroHub mounts the gems' engines itself.
- **One look.** Top bar, sidebar, breadcrumb bar and page styles are shared, so every gem feels the same.
- **One sidebar.** Each gem registers its pages and shows up as a section. A section only appears for people allowed to use it.
- **One place for "who is signed in".** Set it once for all gems.

It is a shell, not a security boundary: hiding a section is navigation. Every Bro gem still authorizes its own pages.

Rails 7.1+, Ruby 3.2+. No database, no JavaScript, no asset pipeline.

## Install

```ruby
gem "bro_hub"
```

Minimum versions: **env_bro 0.2.0** and **safe_bro 0.1.0**. Older EnvBro (0.1.x) has no BroHub support: the installer skips
it with a warning and leaves its old mount alone, so `bundle update env_bro` first.

```sh
bin/rails generate bro_hub:install
```

This sets up the whole dashboard in one go:

1. adds `config/initializers/bro_hub.rb`,
2. mounts BroHub (it asks where, default `/bro_hub`; or `--mount-path=/ops/bro`):
   ```ruby
   mount BroHub::Engine => "/bro_hub"
   ```
3. offers to comment out old direct mounts such as `mount SafeBro::Engine`, since BroHub now mounts those gems itself
   (`--remove-direct-mounts` says yes without asking; without a terminal the lines are left alone with a warning),
4. runs the installer of every Bro gem in your Gemfile (SafeBro's initializer and migrations, EnvBro's, ...).

Existing config is never overwritten: if `config/initializers/bro_hub.rb` (or `env_bro.rb` / `safe_bro.rb`) is there already,
it is skipped, and `--skip` / `--force` / `--pretend` are passed on to every gem's installer. In scripts and agents, pass
`--skip` and `--mount-path=...` so nothing waits on a prompt.

You can also run a gem's own installer on its own: `bin/rails generate safe_bro:install` sets up BroHub first, then SafeBro.
Running both, in any order, mounts BroHub once.

Who is signed in: the default calls `current_user` on your controller, and falls back to `Current.user` (the Rails 8
authentication generator has only that). The top-right label tries `email`, `email_address` (Rails 8) then `name`.

```ruby
# config/initializers/bro_hub.rb
BroHub.configure do |config|
  config.current_user = ->(controller) { controller.current_user }   # default: calls current_user if present
  config.user_label   = ->(user) { user.email }
  config.parent_controller = "::ApplicationController"
end
```

Opening `/bro_hub` sends people to the first section they may use.

## For gem authors: plugging in

**1. Register your section** (in your engine file, so it runs before routes are drawn):

```ruby
BroHub.register :safe_bro,
  label: "SafeBro · audit",              # sidebar heading
  name: "SafeBro",                       # breadcrumb (default: label up to the "·")
  accent: :red,                          # :red :green :violet :amber :blue, or "#hex"
  engine: "SafeBro::Engine",             # BroHub mounts it at /<key>
  order: 10,                             # lower comes first
  visible_to: ->(user) { SafeBro.config.can_audit.call(user) },
  items: [
    { label: "Sessions", path: "/", badge: -> { SafeBro::Session.pending.count } },
    { label: "Flagged commands", path: "/flagged" },
    { label: "Rules", path: "/rules", match: %r{\A/rules} },
    { label: "Raw export", path: "/export", visible_to: ->(user) { user.admin? } }   # per-item visibility
  ]
```

- `path` is relative to your engine. Badges are hidden when `nil` or `0`, and a badge that raises is skipped.
- Active item: exact match for `"/"`, prefix match otherwise, or your own `match:` regexp.
- A section only shows up in the shared sidebar when you pass `engine:` (BroHub then knows where it lives). A gem the host mounts elsewhere still gets the shell, with just its own section.
- Never put anything that came from a user in `accent` or `label`. `accent` is validated; `label` is escaped.

**2. Render inside the shell:**

```ruby
class SafeBro::ApplicationController < ::ApplicationController
  include BroHub::ControllerBase
  bro_hub_section :safe_bro
end
```

`BroHub::ControllerBase` includes `BroHub::Layout` (the layout, and `bro_hub_user`), turns on CSRF protection and opts out of the host app's Pundit `verify_authorized` checks, so every Bro controller behaves the same under any host `ApplicationController`. Override it if your gem has its own idea of who is signed in.

**3. Give your gem an installer** that sets up BroHub first, then itself. Name it `<section key>:install` so
`bro_hub:install` finds it:

```ruby
# lib/generators/safe_bro/install/install_generator.rb
require "generators/bro_hub/installable"

class SafeBro::Generators::InstallGenerator < Rails::Generators::Base
  include BroHub::Generators::Installable   # keep this first: it adds the BroHub step and --mount-path

  def copy_initializer ... end
  def next_steps
    say "Visit #{bro_hub_path}/safe_bro"    # bro_hub_path: where BroHub ended up
  end
end
```

**4. Fill in the page:**

```erb
<% bro_hub_crumb "Console sessions", "#5" %>                         <%# "SafeBro / Console sessions / #5" %>
<% content_for :bro_hub_crumb_actions do %>
  <%= bro_hub_crumb_link "← All sessions", sessions_path %>         <%# right side of the bar %>
<% end %>

<%= bro_hub_hero eyebrow: "console · web-1 (pid 4417)", title: "Session #5", subtitle: "Pending",
      subtitle_tone: :green,                                        # :red :green :amber :violet :muted
      lead: "jane was on a production console for 1m.",
      stats: [ [ 4, "unlocks", :amber ], [ 6, "flagged commands", :red ] ] %>
```

Page styles are plain CSS classes prefixed `bh-` (see `lib/bro_hub/styles.css`): `bh-block`, `bh-split`, `bh-table`/`bh-row`, `bh-tag`, `bh-filters`, `bh-input`, `bh-btn`, `bh-seg`, `bh-log`/`bh-cmd`, `bh-dl`, `bh-pager`, and so on. `bh-tag` is uppercase; add `is-code` for case-sensitive text such as method names. Tables take their columns from `style="--cols: 150px 1fr 80px"`.

## Notes

- The layout loads IBM Plex Mono and Archivo from Google Fonts, and embeds the skull as a `data:` image. Under a strict Content Security Policy allow `fonts.googleapis.com`, `fonts.gstatic.com` and `img-src data:`. Without the fonts it falls back to system fonts. The inline `<style>` uses your CSP nonce when you have one.
- The shell's own pages send `Cache-Control: no-store` and refuse plain HTTP in production (`config.require_ssl`).
- The look is dark only.

## Development

```sh
bin/rails test                                                    # Rails 8.x
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rails test  # Rails 7.1
bin/rubocop
cd test/dummy && bin/rails server                                 # try it: /hub (Alpha, Beta), /solo (Gamma)
```

The dummy app has three fake Bro gems (`test/support/fake_bros`). Alpha and Beta live in the hub, Gamma is mounted on its own.

## License

MIT.
