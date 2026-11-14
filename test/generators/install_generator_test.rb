require "test_helper"
require "generators/bro_hub/install/install_generator"

class BroHub::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests BroHub::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)

  setup do
    prepare_destination
    FileUtils.mkdir_p File.join(destination_root, "config")
    File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
  end

  test "creates the initializer" do
    run_install
    assert_file "config/initializers/bro_hub.rb", /BroHub\.configure/
  end

  test "mounts at the default path when not interactive" do
    run_install
    assert_file "config/routes.rb", %r{mount BroHub::Engine => "/bro_hub"}
  end

  test "mounts at --mount-path, normalizing slashes" do
    run_install "--mount-path=ops/bro/"
    assert_file "config/routes.rb", %r{mount BroHub::Engine => "/ops/bro"}
  end

  test "does not mount twice" do
    run_install
    run_install "--mount-path=/other"
    assert_file "config/routes.rb" do |content|
      assert_equal 1, content.scan("BroHub::Engine").size
    end
  end

  test "installs the Bro gems of the bundle that ship an installer" do
    run_install
    assert_file "config/alpha_installed.txt"
    # Beta and Gamma have no installer: nothing to run, nothing to fail.
    assert_no_file "config/beta_installed.txt"
  end

  test "asks for the mount path once even when it installs gems" do
    run_install "--mount-path=/ops/bro"
    assert_file "config/routes.rb" do |content|
      assert_equal 1, content.scan("BroHub::Engine").size
      assert_match %r{"/ops/bro"}, content
    end
  end

  test "--no-install-gems only sets up the hub" do
    run_install "--no-install-gems"
    assert_no_file "config/alpha_installed.txt"
  end

  test "a gem's own installer sets up the hub, then itself, and nothing runs twice" do
    require "generators/alpha/install/install_generator"
    out = capture(:stdout) { Alpha::Generators::InstallGenerator.start([], destination_root: destination_root) }
    assert_file "config/initializers/bro_hub.rb"
    assert_file "config/alpha_installed.txt"
    assert_file("config/routes.rb") { |content| assert_equal 1, content.scan("BroHub::Engine").size }
    assert_equal 1, out.scan("config/alpha_installed.txt").size
  end

  test "never overwrites an existing initializer" do
    FileUtils.mkdir_p File.join(destination_root, "config/initializers")
    File.write(File.join(destination_root, "config/initializers/bro_hub.rb"), "# mine\n")
    run_install "--force"
    assert_file "config/initializers/bro_hub.rb", /\A# mine\n\z/
  end

  test "keeps the indentation of a commented-out mount" do
    File.write(File.join(destination_root, "config/routes.rb"),
      "Rails.application.routes.draw do\n  mount Alpha::Engine => \"/old\"\nend\n")
    run_install "--remove-direct-mounts"
    assert_file "config/routes.rb", /^  # BroHub mounts this now: mount Alpha::Engine/
  end

  test "comments out old direct mounts when asked" do
    File.write(File.join(destination_root, "config/routes.rb"),
      "Rails.application.routes.draw do\n  mount Alpha::Engine => \"/old\"\n  mount Beta::Engine => \"/old-beta\"\nend\n")
    run_install "--remove-direct-mounts"
    assert_file "config/routes.rb" do |content|
      assert_match %r{^\s*# BroHub mounts this now: mount Alpha::Engine}, content
      assert_match %r{^\s*# BroHub mounts this now: mount Beta::Engine}, content
      assert_no_match(/^\s*mount (Alpha|Beta)::Engine/, content)
    end
  end

  test "leaves old direct mounts alone, with a warning, when not asked and not interactive" do
    File.write(File.join(destination_root, "config/routes.rb"),
      "Rails.application.routes.draw do\n  mount Alpha::Engine => \"/old\"\nend\n")
    out = run_install
    assert_file "config/routes.rb", /^\s*mount Alpha::Engine/
    assert_match(/still mounted directly/, out)
  end

  test "an already commented-out mount is not touched" do
    File.write(File.join(destination_root, "config/routes.rb"),
      "Rails.application.routes.draw do\n  # mount Alpha::Engine => \"/old\"\nend\n")
    out = run_install "--remove-direct-mounts"
    assert_no_match(/still mounted directly/, out)
    assert_file "config/routes.rb", /^\s*# mount Alpha::Engine => "\/old"$/
  end

  private
    def run_install(*args)
      capture(:stdout) { generator([], args, destination_root: destination_root).invoke_all }
    end
end
