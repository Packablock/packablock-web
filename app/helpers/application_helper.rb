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

  def dev_instance?
    Rails.env.development? || request.host.end_with?(".dev.adwb.io") || request.host.include?("localhost") || request.host.include?("127.0.0.1")
  end
end
