require "test_helper"
require "ostruct"

class RepositoriesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(
      email: "admin@acme.com",
      password: "password123",
      password_confirmation: "password123",
      superuser: false
    )

    @project = @admin.projects.create!(name: "Acme Production")
    @project_repo = ProjectRepository.create!(project: @project, repo_id: 42)
  end

  # Helper to temporarily stub a class instance method in pure Ruby
  def stub_call(klass, method_name, stubbed_value)
    original_method = klass.instance_method(method_name) rescue nil

    klass.define_method(method_name) do |*args, **kwargs|
      stubbed_value
    end

    yield
  ensure
    if original_method
      klass.define_method(method_name, original_method)
    else
      klass.send(:remove_method, method_name) rescue nil
    end
  end

  # Helper to temporarily stub a class singleton method in pure Ruby
  def stub_stripe_call(klass, method_name, stubbed_value)
    original_method = klass.method(method_name) rescue nil

    klass.define_singleton_method(method_name) do |*args, **kwargs|
      stubbed_value
    end

    yield
  ensure
    if original_method
      klass.define_singleton_method(method_name, &original_method)
    else
      klass.singleton_class.send(:remove_method, method_name) rescue nil
    end
  end

  test "should redirect repository show if not authenticated" do
    get repository_path(42)
    assert_redirected_to new_admin_session_path
  end

  test "should render repository show page for authenticated admin" do
    mock_repos = {
      "repos" => [
        { "id" => 42, "owner" => "acme", "repo" => "app", "is_premium" => 0, "verification_status" => "verified", "registration_token" => "pb_token_mock123" }
      ]
    }

    stub_call(PackablockCore::Client, :list_repos, mock_repos) do
      sign_in @admin
      get repository_path(42)
      assert_response :success
      assert_select "h1", text: "acme/app"
      assert_select "span", text: "Standard Tier"
    end
  end

  test "should toggle premium successfully without Stripe if api_key is unconfigured" do
    mock_repos = {
      "repos" => [
        { "id" => 42, "owner" => "acme", "repo" => "app", "is_premium" => 0, "registration_token" => "pb_token_mock123" }
      ]
    }

    stub_call(PackablockCore::Client, :list_repos, mock_repos) do
      stub_call(PackablockCore::Client, :toggle_premium, { "success" => true }) do
        original_key = Stripe.api_key
        Stripe.api_key = nil

        sign_in @admin
        post toggle_premium_repository_path(42)

        assert_redirected_to dashboard_path

        Stripe.api_key = original_key
      end
    end
  end

  test "should create subscription when upgrading to premium if Stripe is configured" do
    mock_repos = {
      "repos" => [
        { "id" => 42, "owner" => "acme", "repo" => "app", "is_premium" => 0, "registration_token" => "pb_token_mock123" }
      ]
    }

    mock_customer = OpenStruct.new(id: "cus_mock42")
    mock_pms = OpenStruct.new(data: [])
    mock_sub = OpenStruct.new(id: "sub_mock99")

    stub_call(PackablockCore::Client, :list_repos, mock_repos) do
      stub_call(PackablockCore::Client, :toggle_premium, { "success" => true }) do
        stub_stripe_call(Stripe::Customer, :create, mock_customer) do
          stub_stripe_call(Stripe::PaymentMethod, :list, mock_pms) do
            stub_stripe_call(Stripe::Subscription, :create, mock_sub) do
              original_key = Stripe.api_key
              Stripe.api_key = "sk_test_mock"

              sign_in @admin
              post toggle_premium_repository_path(42)

              assert_redirected_to dashboard_path
              @admin.reload
              assert_equal "cus_mock42", @admin.stripe_customer_id

              @project_repo.reload
              assert_equal "sub_mock99", @project_repo.stripe_subscription_id

              Stripe.api_key = original_key
            end
          end
        end
      end
    end
  end

  test "should redirect to billing page on upgrade in production if no payment method configured" do
    mock_repos = {
      "repos" => [
        { "id" => 42, "owner" => "acme", "repo" => "app", "is_premium" => 0, "registration_token" => "pb_token_mock123" }
      ]
    }

    mock_customer = OpenStruct.new(id: "cus_mock42")
    mock_pms = OpenStruct.new(data: [])

    stub_call(PackablockCore::Client, :list_repos, mock_repos) do
      # Stub production? on Rails.env to return true, avoiding global env side effects
      Rails.env.define_singleton_method(:production?) { true }
      begin
        stub_stripe_call(Stripe::Customer, :create, mock_customer) do
          stub_stripe_call(Stripe::PaymentMethod, :list, mock_pms) do
            original_key = Stripe.api_key
            Stripe.api_key = "sk_test_mock"
            @admin.update!(stripe_customer_id: "cus_mock42")

            sign_in @admin
            post toggle_premium_repository_path(42)

            assert_redirected_to billing_path
            follow_redirect!
            assert_match "Please add a payment method", response.body

            Stripe.api_key = original_key
          end
        end
      ensure
        Rails.env.singleton_class.send(:remove_method, :production?) rescue nil
      end
    end
  end

  test "should cancel subscription when downgrading to standard if subscription ID present" do
    mock_repos = {
      "repos" => [
        { "id" => 42, "owner" => "acme", "repo" => "app", "is_premium" => 1, "registration_token" => "pb_token_mock123" }
      ]
    }

    @project_repo.update!(stripe_subscription_id: "sub_existing_123")

    mock_pms = OpenStruct.new(data: [])
    cancel_called_with = nil

    # We can track method calls using simple ruby closures inside the stub value:
    stub_call(PackablockCore::Client, :list_repos, mock_repos) do
      stub_call(PackablockCore::Client, :toggle_premium, { "success" => true }) do
        stub_stripe_call(Stripe::PaymentMethod, :list, mock_pms) do
          # Custom stub to track subscription cancel parameter
          original_cancel = Stripe::Subscription.method(:cancel) rescue nil
          Stripe::Subscription.define_singleton_method(:cancel) do |sub_id, *args|
            cancel_called_with = sub_id
          end

          begin
            original_key = Stripe.api_key
            Stripe.api_key = "sk_test_mock"
            @admin.update!(stripe_customer_id: "cus_mock42")

            sign_in @admin
            post toggle_premium_repository_path(42)

            assert_redirected_to dashboard_path
            assert_equal "sub_existing_123", cancel_called_with

            @project_repo.reload
            assert_nil @project_repo.stripe_subscription_id

            Stripe.api_key = original_key
          ensure
            if original_cancel
              Stripe::Subscription.define_singleton_method(:cancel, &original_cancel)
            else
              Stripe::Subscription.singleton_class.send(:remove_method, :cancel) rescue nil
            end
          end
        end
      end
    end
  end
end
