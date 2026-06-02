class RepositoriesController < ApplicationController
  before_action :authenticate_admin!

  def show
    client = PackablockCore::Client.new
    begin
      repos_data = client.list_repos
      all_repos = repos_data["repos"] || []
      @repository = all_repos.find { |r| r["id"] == params[:id].to_i }
    rescue => e
      Rails.logger.error("Failed to fetch repository in show: #{e.message}")
    end

    if @repository.nil?
      redirect_to dashboard_path, alert: "Repository not found."
      return
    end

    # Find project mapping if any
    mapping = ProjectRepository.find_by(repo_id: @repository["id"])
    @project = mapping&.project
  end

  # GET /repositories/:id/tree
  def tree
    client = PackablockCore::Client.new
    begin
      tree_data = client.fetch_tree(repo_id: params[:id])
      render json: tree_data
    rescue => e
      Rails.logger.error("Failed to proxy tree data: #{e.message}")
      render json: { error: "Failed to load tree data from registry API" }, status: :bad_gateway
    end
  end

  # POST /repositories/:id/toggle_premium
  def toggle_premium
    client = PackablockCore::Client.new
    begin
      client.toggle_premium(params[:id])
      redirect_back fallback_location: dashboard_path, notice: "Access tier updated successfully."
    rescue => e
      redirect_back fallback_location: dashboard_path, alert: "Failed to update access tier: #{e.message}"
    end
  end

  # POST /repositories/:id/revoke
  def revoke
    client = PackablockCore::Client.new
    begin
      client.revoke(params[:id])
      redirect_back fallback_location: dashboard_path, notice: "Repository authentication token successfully revoked."
    rescue => e
      redirect_back fallback_location: dashboard_path, alert: "Failed to revoke token: #{e.message}"
    end
  end

  # POST /repositories/purge_stale
  def purge_stale
    client = PackablockCore::Client.new
    begin
      result = client.purge_stale
      purged_count = result["purgedCount"] || 0
      redirect_back fallback_location: dashboard_path, notice: "Garbage collection completed. Purged #{purged_count} stale unverified premium records."
    rescue => e
      redirect_back fallback_location: dashboard_path, alert: "Failed to run garbage collection: #{e.message}"
    end
  end
end
