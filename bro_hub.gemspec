require_relative "lib/bro_hub/version"

Gem::Specification.new do |spec|
  spec.name        = "bro_hub"
  spec.version     = BroHub::VERSION
  spec.authors     = [ "Ruby Dev SRL" ]
  spec.email       = [ "office@rubydev.ro" ]
  spec.summary     = "One dashboard shell for the Bro gems (EnvBro, SafeBro, ...)."
  spec.description = "BroHub is the shared admin shell: one mount point, one layout, one sidebar and one place to " \
                     "configure who is signed in. Each Bro gem registers its pages and shows up as a section. " \
                     "Sections only appear for people who may use them."
  spec.homepage    = "https://www.rubydev.ro"
  spec.license     = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rubydevro/bro_hub"
  spec.metadata["bug_tracker_uri"] = "https://github.com/rubydevro/bro_hub/issues"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.2"
  spec.add_dependency "rails", ">= 7.1"
end
