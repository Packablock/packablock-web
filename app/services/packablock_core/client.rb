module PackablockCore
  class Client
    class Error < StandardError; end

    attr_reader :connection

    def initialize(base_url: nil)
      @base_url = base_url || ENV.fetch("REGISTRY_API_URL", "http://localhost:3030")
      @token = ENV.fetch("INTERNAL_REGISTRY_TOKEN", "internal_secret_token_1234")
      
      @connection = Faraday.new(url: @base_url) do |conn|
        conn.headers["X-Packablock-Internal-Token"] = @token
        conn.headers["Content-Type"] = "application/json"
        conn.headers["Accept"] = "application/json"
        conn.adapter Faraday.default_adapter
      end
    end

    def fetch_system_status
      response = @connection.get("/api/v1/internal/system/status")
      handle_response(response)
    end

    def list_repos
      response = @connection.get("/api/v1/internal/repos")
      handle_response(response)
    end

    def fetch_tree(repo_id: nil, owner: nil, repo: nil)
      params = {}
      params[:repo_id] = repo_id if repo_id
      params[:owner] = owner if owner
      params[:repo] = repo if repo
      
      response = @connection.get("/api/v1/internal/chain/tree", params)
      handle_response(response)
    end

    def toggle_premium(repo_id)
      response = @connection.post("/api/v1/internal/repo/#{repo_id}/toggle-premium")
      handle_response(response)
    end

    def revoke(repo_id)
      response = @connection.post("/api/v1/internal/repo/#{repo_id}/revoke")
      handle_response(response)
    end

    def purge_stale
      response = @connection.post("/api/v1/internal/purge-stale")
      handle_response(response)
    end

    private

    def handle_response(response)
      if response.success?
        JSON.parse(response.body) rescue response.body
      else
        raise Error, "Registry API Error: #{response.status} - #{response.body}"
      end
    end
  end
end
