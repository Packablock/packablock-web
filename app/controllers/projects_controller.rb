class ProjectsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :link_repository, :unlink_repository ]

  def index
    @projects = Project.includes(:project_repositories).all
  end

  def show
    client = PackablockCore::Client.new
    begin
      repos_data = client.list_repos
      @all_repositories = repos_data["repos"] || []
    rescue => e
      Rails.logger.error("Failed to fetch all repositories in show project: #{e.message}")
      @all_repositories = []
    end

    # Filter repositories belonging to this project
    linked_repo_ids = @project.project_repositories.pluck(:repo_id)
    @linked_repositories = @all_repositories.select { |r| linked_repo_ids.include?(r["id"]) }
    @unlinked_repositories = @all_repositories.reject { |r| linked_repo_ids.include?(r["id"]) }
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to dashboard_path, notice: "Project '#{@project.name}' successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      redirect_to dashboard_path, notice: "Project '#{@project.name}' successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to dashboard_path, notice: "Project successfully deleted."
  end

  # POST /projects/:id/link_repository
  def link_repository
    repo_id = params[:repo_id].to_i
    if repo_id > 0
      # Ensure it is not already linked elsewhere
      ProjectRepository.where(repo_id: repo_id).destroy_all
      @project.project_repositories.create(repo_id: repo_id)
      redirect_to project_path(@project), notice: "Repository successfully linked to project."
    else
      redirect_to project_path(@project), alert: "Invalid repository ID."
    end
  end

  # DELETE /projects/:id/unlink_repository
  def unlink_repository
    repo_id = params[:repo_id].to_i
    @project.project_repositories.find_by(repo_id: repo_id)&.destroy
    redirect_to project_path(@project), notice: "Repository unlinked successfully."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name)
  end
end
