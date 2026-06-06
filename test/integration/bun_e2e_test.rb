require "test_helper"
require "faraday"
require "json"

class BunE2eTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    # 1. Clean up old database files
    @db_file = "/home/aaron/dev/packablock/packablock-registry/packablock_test_bun_e2e.sqlite"
    File.delete(@db_file) if File.exist?(@db_file)

    @path_with_bun = "/home/aaron/.bun/bin:#{ENV['PATH']}"
    @original_registry_url = ENV["REGISTRY_API_URL"]
    ENV["REGISTRY_API_URL"] = "http://localhost:3031"

    # 2. Start registry server in background on port 3031
    @registry_pid = spawn(
      { "DATABASE_FILE" => "packablock_test_bun_e2e.sqlite", "PORT" => "3031", "MOCK_GITHUB_API" => "true", "PATH" => @path_with_bun },
      "bun start",
      chdir: "/home/aaron/dev/packablock/packablock-registry",
      out: "/dev/null",
      err: "/dev/null"
    )

    # Wait for registry to boot up (timeout 15 seconds)
    started = false
    30.times do
      begin
        response = Faraday.get("http://localhost:3031/api/v1/log/pull")
        if response.status
          started = true
          break
        end
      rescue Faraday::ConnectionFailed
        sleep 0.5
      end
    end

    unless started
      raise "Failed to start registry server for E2E test"
    end
  end

  def teardown
    # Stop registry server
    if @registry_pid
      Process.kill("KILL", @registry_pid)
      Process.wait(@registry_pid) rescue nil
    end
    File.delete(@db_file) if File.exist?(@db_file)
    ENV["REGISTRY_API_URL"] = @original_registry_url
  end

  test "simulates registering bun repo, replaying history, forgetting bun.lockb, and verifying web view" do
    # 1. Register repo "bun" for organization "oven-sh" standard tier
    conn = Faraday.new(url: "http://localhost:3031")
    res = conn.post("/api/v1/acme/new-account", { owner: "oven-sh", repo: "bun", isPremium: false }.to_json, { "Content-Type" => "application/json" })
    assert res.success?, "Failed to register new standard account"
    reg_data = JSON.parse(res.body)
    token = reg_data["registrationToken"]
    assert token.present?, "Registration token was empty"

    # 2. Run our helper setup-bun-chain.ts to replay and push the chain
    setup_script = "/home/aaron/dev/packablock/packablock-demo/tests/setup-bun-chain.ts"
    success = system({ "PATH" => @path_with_bun }, "bun run #{setup_script} #{token} http://localhost:3031")
    assert success, "setup-bun-chain.ts failed to run successfully"

    # 3. Create Admin user for "oven-sh" org
    admin = Admin.create!(
      email: "manager@oven-sh.com",
      password: "password123",
      password_confirmation: "password123",
      superuser: false
    )

    # 4. Sign in as admin
    sign_in admin

    # 5. Fetch dashboard to verify "oven-sh/bun" repository is visible or exists
    client = PackablockCore::Client.new
    repos_data = client.list_repos
    all_repos = repos_data["repos"] || []
    bun_repo = all_repos.find { |r| r["owner"] == "oven-sh" && r["repo"] == "bun" }
    assert bun_repo.present?, "bun repository not found in registry repos list"
    repo_id = bun_repo["id"]

    # 6. Create a Project and link the repository to it so we can test dashboard and show page
    project = admin.projects.create!(name: "Oven-sh Production Environment")
    ProjectRepository.create!(project: project, repo_id: repo_id)

    # 7. Request the project show page and assert it contains "bun" repo
    get project_path(project)
    assert_response :success
    assert_select "h1", text: /Oven-sh Production/
    assert_match "oven-sh/bun", response.body

    # 8. Request the repository show page
    get repository_path(repo_id)
    assert_response :success
    assert_match "oven-sh/bun", response.body

    # 9. Query the tree data endpoint `/repositories/:id/tree` and assert the chain tree structure
    get tree_repository_path(repo_id)
    assert_response :success
    tree_data = JSON.parse(response.body)
    puts "DEBUG TREE DATA: #{tree_data.to_json}"
    assert_equal true, tree_data["success"]
    assert tree_data["blockCount"] > 0, "No blocks in tree"

    # Verify that the tree contains the forget event for bun.lockb
    forget_event_found = false
    traverse_nodes = ->(n) {
      if n["data_payload"] && n["data_payload"].include?("chain_event: forget") && n["data_payload"].include?("bun.lockb")
        forget_event_found = true
      end
      n["children"]&.each { |child| traverse_nodes.call(child) }
    }

    traverse_nodes.call(tree_data["tree"])
    assert forget_event_found, "Forget block for bun.lockb not found in repository tree data"
  end
end
