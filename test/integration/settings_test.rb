require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(
      email: "test-admin@packablock.com",
      password: "password123",
      password_confirmation: "password123",
      superuser: false
    )

    @superuser = Admin.create!(
      email: "root-admin@packablock.com",
      password: "password123",
      password_confirmation: "password123",
      superuser: true
    )
  end

  test "should redirect settings page if not authenticated" do
    get settings_path
    assert_redirected_to new_admin_session_path
  end

  test "should display settings page for authenticated standard admin" do
    sign_in @admin
    get settings_path
    assert_response :success
    assert_select "h1", text: "Account Settings"
    assert_select "span", text: "Standard Admin"
    assert_select "span", text: @admin.email
    assert_select "p", text: /Standard administrator account/
  end

  test "should display settings page for superuser with GC options" do
    sign_in @superuser
    get settings_path
    assert_response :success
    assert_select "span", text: "Superuser"
    assert_select "p", text: /Root superuser account/
    assert_select "button", text: /Force GC on Stale Signups/
  end

  test "should update email successfully with correct password" do
    sign_in @admin
    patch settings_path, params: {
      admin: {
        email: "new-email@packablock.com",
        current_password: "password123"
      }
    }
    assert_redirected_to settings_path
    follow_redirect!
    assert_match "Account settings updated successfully.", response.body
    @admin.reload
    assert_equal "new-email@packablock.com", @admin.email
  end

  test "should fail to update email with incorrect password" do
    sign_in @admin
    patch settings_path, params: {
      admin: {
        email: "new-email@packablock.com",
        current_password: "wrongpassword"
      }
    }
    assert_response :unprocessable_entity
    assert_select "div", text: /prevented saving/
    @admin.reload
    assert_equal "test-admin@packablock.com", @admin.email
  end

  test "should update password successfully with correct current password" do
    sign_in @admin
    patch settings_path, params: {
      admin: {
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "password123"
      }
    }
    assert_redirected_to settings_path
    follow_redirect!
    assert_match "Account settings updated successfully.", response.body

    # Try logging in with the new password to confirm change
    sign_out @admin
    post admin_session_path, params: {
      admin: {
        email: @admin.email,
        password: "newpassword123"
      }
    }
    assert_redirected_to root_path
  end
end
