# Seed default administrator account if it doesn't exist
Admin.find_or_create_by!(email: "admin@packablock.com") do |admin|
  admin.password = "admin_secret_token_1234"
  admin.password_confirmation = "admin_secret_token_1234"
  puts " seeded default admin account: admin@packablock.com / admin_secret_token_1234"
end
