# Stripe Dual-Layer Configuration Initializer
# - Development/Test: Loads sandbox keys from .env/environment
# - Production: Decrypts production API keys via GCP Key Management Service (KMS)

if Rails.env.production?
  if ENV["STRIPE_PROD_SECRET_KEY_CIPHERTEXT"].present?
    begin
      require "google/cloud/kms"
      require "base64"

      client = Google::Cloud::Kms.key_management_service

      project_id = ENV.fetch("GCP_PROJECT_ID")
      location   = ENV.fetch("GCP_KMS_LOCATION", "global")
      key_ring   = ENV.fetch("GCP_KMS_KEY_RING")
      key_name   = ENV.fetch("GCP_KMS_KEY_NAME")

      crypto_key_path = client.crypto_key_path(
        project: project_id,
        location: location,
        key_ring: key_ring,
        crypto_key: key_name
      )

      ciphertext = Base64.decode64(ENV["STRIPE_PROD_SECRET_KEY_CIPHERTEXT"])
      response = client.decrypt(name: crypto_key_path, ciphertext: ciphertext)

      Stripe.api_key = response.plaintext.strip
    rescue => e
      Rails.logger.error("Failed to decrypt Stripe production key using GCP KMS: #{e.message}")
      # Fallback to unencrypted key if present
      Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
    end
  else
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  end
else
  # Development / Test
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
end
