require "test_helper"
require "ostruct"

class PackablockCoreClientTest < ActiveSupport::TestCase
  class MockConnection
    attr_reader :last_get_url, :last_get_params, :last_post_url
    attr_accessor :response_success, :response_body, :response_status, :headers

    def initialize
      @response_success = true
      @response_body = '{"success":true}'
      @response_status = 200
      @headers = {}
    end

    def get(url, params = nil)
      @last_get_url = url
      @last_get_params = params
      OpenStruct.new(success?: @response_success, status: @response_status, body: @response_body)
    end

    def post(url, params = nil)
      @last_post_url = url
      OpenStruct.new(success?: @response_success, status: @response_status, body: @response_body)
    end
  end

  def setup
    @original_token = ENV["INTERNAL_REGISTRY_TOKEN"]
    ENV["INTERNAL_REGISTRY_TOKEN"] = "my_test_internal_token"
  end

  def teardown
    ENV["INTERNAL_REGISTRY_TOKEN"] = @original_token
  end

  test "initialization injects custom token from environment" do
    client = PackablockCore::Client.new
    assert_equal "my_test_internal_token", client.connection.headers["X-Packablock-Internal-Token"]
    assert_equal "application/json", client.connection.headers["Content-Type"]
    assert_equal "application/json", client.connection.headers["Accept"]
  end

  test "initialization falls back to default token if env is missing" do
    ENV.delete("INTERNAL_REGISTRY_TOKEN")
    client = PackablockCore::Client.new
    assert_equal "internal_secret_token_1234", client.connection.headers["X-Packablock-Internal-Token"]
  end

  test "fetch_system_status queries correct endpoint and returns parsed json" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    mock_conn.response_body = '{"success":true,"status":"Secured"}'
    client.instance_variable_set(:@connection, mock_conn)

    response = client.fetch_system_status
    assert_equal "/api/v1/internal/system/status", mock_conn.last_get_url
    assert_equal true, response["success"]
    assert_equal "Secured", response["status"]
  end

  test "list_repos queries correct endpoint and returns parsed json" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    mock_conn.response_body = '{"success":true,"repos":[]}'
    client.instance_variable_set(:@connection, mock_conn)

    response = client.list_repos
    assert_equal "/api/v1/internal/repos", mock_conn.last_get_url
    assert_equal true, response["success"]
    assert_empty response["repos"]
  end

  test "fetch_tree queries correct endpoint with custom query params" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    mock_conn.response_body = '{"success":true,"tree":{}}'
    client.instance_variable_set(:@connection, mock_conn)

    response = client.fetch_tree(repo_id: 12, owner: "testowner", repo: "testrepo")
    assert_equal "/api/v1/internal/chain/tree", mock_conn.last_get_url
    assert_equal({ repo_id: 12, owner: "testowner", repo: "testrepo" }, mock_conn.last_get_params)
    assert_equal true, response["success"]
  end

  test "toggle_premium queries correct endpoint" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    client.instance_variable_set(:@connection, mock_conn)

    response = client.toggle_premium(42)
    assert_equal "/api/v1/internal/repo/42/toggle-premium", mock_conn.last_post_url
    assert_equal true, response["success"]
  end

  test "revoke queries correct endpoint" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    client.instance_variable_set(:@connection, mock_conn)

    response = client.revoke(99)
    assert_equal "/api/v1/internal/repo/99/revoke", mock_conn.last_post_url
    assert_equal true, response["success"]
  end

  test "purge_stale queries correct endpoint" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    mock_conn.response_body = '{"success":true,"purgedCount":3}'
    client.instance_variable_set(:@connection, mock_conn)

    response = client.purge_stale
    assert_equal "/api/v1/internal/purge-stale", mock_conn.last_post_url
    assert_equal true, response["success"]
    assert_equal 3, response["purgedCount"]
  end

  test "raises Error when registry response is unsuccessful" do
    client = PackablockCore::Client.new
    mock_conn = MockConnection.new
    mock_conn.response_success = false
    mock_conn.response_status = 401
    mock_conn.response_body = "Unauthorized access"
    client.instance_variable_set(:@connection, mock_conn)

    assert_raises(PackablockCore::Client::Error) do
      client.fetch_system_status
    end
  end
end
