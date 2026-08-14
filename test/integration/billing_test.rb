require "test_helper"
require "ostruct"

class BillingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = Admin.create!(
      email: "billing-admin@packablock.com",
      password: "password123",
      password_confirmation: "password123",
      superuser: false
    )
  end

  # Helper to temporarily stub a class method in pure Ruby
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

  test "should redirect billing page if not authenticated" do
    get billing_path
    assert_redirected_to new_admin_session_path
  end

  test "should display billing page with unconfigured state if stripe API key is missing" do
    original_key = Stripe.api_key
    Stripe.api_key = nil

    sign_in @admin
    get billing_path
    assert_response :success
    assert_select "p", text: /Stripe Key Unconfigured/

    Stripe.api_key = original_key
  end

  test "should display empty state if customer has no payment methods" do
    @admin.update!(stripe_customer_id: "cus_test123")
    mock_list_response = OpenStruct.new(data: [])

    stub_stripe_call(Stripe::PaymentMethod, :list, mock_list_response) do
      original_key = Stripe.api_key
      Stripe.api_key = "sk_test_mock"

      sign_in @admin
      get billing_path
      assert_response :success
      assert_select "p", text: /No active billing methods/

      Stripe.api_key = original_key
    end
  end

  test "should display payment methods list if stripe is configured and customer exists" do
    @admin.update!(stripe_customer_id: "cus_test123")

    mock_pm = OpenStruct.new(
      card: OpenStruct.new(brand: "visa", last4: "4242", exp_month: 12, exp_year: 2028)
    )
    mock_list_response = OpenStruct.new(data: [ mock_pm ])

    stub_stripe_call(Stripe::PaymentMethod, :list, mock_list_response) do
      original_key = Stripe.api_key
      Stripe.api_key = "sk_test_mock"

      sign_in @admin
      get billing_path
      assert_response :success
      assert_match "VISA •••• 4242", response.body
      assert_match "Expires 12/2028", response.body

      Stripe.api_key = original_key
    end
  end

  test "should redirect to billing portal session URL on portal session post" do
    mock_customer = OpenStruct.new(id: "cus_new123")
    mock_session = OpenStruct.new(url: "https://billing.stripe.com/session/mock123")

    stub_stripe_call(Stripe::Customer, :create, mock_customer) do
      stub_stripe_call(Stripe::BillingPortal::Session, :create, mock_session) do
        original_key = Stripe.api_key
        Stripe.api_key = "sk_test_mock"

        sign_in @admin
        post portal_session_billing_path

        assert_redirected_to "https://billing.stripe.com/session/mock123"
        @admin.reload
        assert_equal "cus_new123", @admin.stripe_customer_id

        Stripe.api_key = original_key
      end
    end
  end

  test "should decrypt production Stripe key using GCP KMS when in production" do
    production_env = ActiveSupport::StringInquirer.new("production")

    mock_kms_client = OpenStruct.new
    mock_kms_client.define_singleton_method(:crypto_key_path) do |**args|
      "projects/p/locations/l/keyRings/kr/cryptoKeys/k"
    end
    mock_kms_client.define_singleton_method(:decrypt) do |**args|
      OpenStruct.new(plaintext: "decrypted_secret_key_123")
    end

    original_api_key = Stripe.api_key

    stub_stripe_call(Google::Cloud::Kms, :key_management_service, mock_kms_client) do
      stub_stripe_call(Rails, :env, production_env) do
        ENV["STRIPE_PROD_SECRET_KEY_CIPHERTEXT"] = "c2FuZGJveF9rZXk="
        ENV["GCP_PROJECT_ID"] = "proj"
        ENV["GCP_KMS_KEY_RING"] = "ring"
        ENV["GCP_KMS_KEY_NAME"] = "key"

        load Rails.root.join("config/initializers/stripe.rb")

        assert_equal "decrypted_secret_key_123", Stripe.api_key
      ensure
        ENV.delete("STRIPE_PROD_SECRET_KEY_CIPHERTEXT")
        ENV.delete("GCP_PROJECT_ID")
        ENV.delete("GCP_KMS_KEY_RING")
        ENV.delete("GCP_KMS_KEY_NAME")
      end
    end
  ensure
    Stripe.api_key = original_api_key
  end
end
