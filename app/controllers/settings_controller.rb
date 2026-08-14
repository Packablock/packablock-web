class SettingsController < ApplicationController
  before_action :authenticate_admin!

  def show
    prepare_settings_data
  end

  def update
    @admin = current_admin

    # Check if they are trying to update credentials (email or password)
    # Devise's update_with_password verifies current_password.
    # If they aren't changing email or password, we can skip verification,
    # but email and password are the only editable attributes for Admin.
    successfully_updated = if admin_params[:password].present? || admin_params[:email] != @admin.email
      @admin.update_with_password(admin_params)
    else
      @admin.update_without_password(admin_params.except(:current_password))
    end

    if successfully_updated
      bypass_sign_in(@admin) # Keep the admin logged in after password change
      redirect_to settings_path, notice: "Account settings updated successfully."
    else
      prepare_settings_data
      render :show, status: :unprocessable_entity
    end
  end

  private

  def prepare_settings_data
    @admin = current_admin
    @projects = @admin.superuser? ? Project.includes(:project_repositories).all : @admin.projects.includes(:project_repositories)

    client = PackablockCore::Client.new
    @registry_url = ENV.fetch("REGISTRY_API_URL", "http://localhost:3030")
    @registry_token_masked = ENV.fetch("INTERNAL_REGISTRY_TOKEN", "internal_secret_token_1234")
    if @registry_token_masked.length > 8
      @registry_token_masked = @registry_token_masked[0..3] + "..." + @registry_token_masked[-4..-1]
    else
      @registry_token_masked = "****"
    end

    begin
      @system_status = client.fetch_system_status
      @registry_online = true
    rescue => e
      Rails.logger.error("Failed to fetch registry status for settings: #{e.message}")
      @system_status = { "status" => "Offline", "projectsCount" => 0, "reposCount" => 0 }
      @registry_online = false
    end
  end

  def admin_params
    params.require(:admin).permit(:email, :password, :password_confirmation, :current_password)
  end
end
