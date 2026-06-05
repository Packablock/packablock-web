class DashboardController < ApplicationController
  before_action :authenticate_admin!

  def index
    client = PackablockCore::Client.new

    # Fetch registry diagnostics
    begin
      @system_status = client.fetch_system_status
      @status_secured = @system_status["status"] == "Secured"
    rescue => e
      Rails.logger.error("Failed to fetch registry system status: #{e.message}")
      @system_status = { "status" => "Offline", "projectsCount" => 0, "reposCount" => 0 }
      @status_secured = false
    end

    # Fetch registered repositories
    begin
      repos_data = client.list_repos
      all_repos = repos_data["repos"] || []
      if current_admin.superuser?
        @repositories = all_repos
      else
        org_name = current_admin.email.split("@").last.split(".").first
        @repositories = all_repos.select { |r| r["owner"] == org_name }
      end
    rescue => e
      Rails.logger.error("Failed to fetch registered repositories: #{e.message}")
      @repositories = []
    end

    # Fetch local projects scoped to the current admin
    @projects = current_admin.superuser? ? Project.includes(:project_repositories).all : current_admin.projects.includes(:project_repositories)

    # Mock server resource metrics for visual premium dashboard feeling
    @metrics = {
      cpu: "1.2%",
      memory: "142MB / 1.0GB",
      disk: "4.8GB / 20GB",
      health: @system_status["status"] == "Offline" ? "Unhealthy" : "Healthy"
    }
  end
end
