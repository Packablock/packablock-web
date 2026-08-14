module ApplicationHelper
  def org_or_email_for(admin)
    return unless admin

    email = admin.email
    domain = email.split("@").last.to_s.downcase

    # Generic public email domains to treat as "no org"
    public_domains = %w[gmail.com yahoo.com hotmail.com outlook.com icloud.com mail.com]

    if public_domains.include?(domain)
      email
    else
      domain.split(".").first.capitalize
    end
  end

  def app_version
    if Rails.env.development?
      version_file = Rails.root.join("config/version.txt")
      File.exist?(version_file) ? File.read(version_file).strip : "1.0.0.dev"
    else
      APP_VERSION
    end
  end
end
