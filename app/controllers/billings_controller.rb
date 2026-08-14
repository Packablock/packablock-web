class BillingsController < ApplicationController
  before_action :authenticate_admin!

  def show
    @admin = current_admin
    @stripe_configured = Stripe.api_key.present?

    if @stripe_configured && @admin.stripe_customer_id.present?
      begin
        @payment_methods = Stripe::PaymentMethod.list({
          customer: @admin.stripe_customer_id,
          type: "card"
        }).data
      rescue => e
        Rails.logger.error("Failed to retrieve payment methods from Stripe: #{e.message}")
        @payment_methods = []
        @stripe_error = "Stripe API connection failed: #{e.message}"
      end
    else
      @payment_methods = []
    end
  end

  def portal_session
    @admin = current_admin

    unless Stripe.api_key.present?
      redirect_to billing_path, alert: "Stripe sandbox is not configured (missing STRIPE_SECRET_KEY)."
      return
    end

    begin
      # 1. Create a customer if they don't have one yet
      if @admin.stripe_customer_id.blank?
        customer = Stripe::Customer.create({
          email: @admin.email,
          metadata: { admin_id: @admin.id, environment: Rails.env }
        })
        @admin.update!(stripe_customer_id: customer.id)
      end

      # 2. Create Billing Portal Session
      session = Stripe::BillingPortal::Session.create({
        customer: @admin.stripe_customer_id,
        return_url: billing_url
      })

      # 3. Redirect to Stripe Customer Portal
      redirect_to session.url, allow_other_host: true
    rescue => e
      Rails.logger.error("Failed to initiate billing portal session: #{e.message}")
      redirect_to billing_path, alert: "Stripe error: #{e.message}"
    end
  end
end
