# Seed default administrator account if it doesn't exist
admin = Admin.find_or_initialize_by(email: "admin@packablock.com")
admin.password = "admin_secret_token_1234"
admin.password_confirmation = "admin_secret_token_1234"
admin.superuser = true
admin.save!
puts " seeded default admin account: admin@packablock.com / admin_secret_token_1234 (Superuser)"

# Seed end-user for Acme org if it doesn't exist
acme_user = Admin.find_or_initialize_by(email: "user@acme.com")
acme_user.password = "acme_secret_token_1234"
acme_user.password_confirmation = "acme_secret_token_1234"
acme_user.superuser = false
acme_user.save!
puts " seeded Acme end-user account: user@acme.com / acme_secret_token_1234"

# Seed default logical projects
defense = Project.find_or_create_by!(name: "Supply Chain Defense Panel")
defense.update!(admin: admin)

ecommerce = Project.find_or_create_by!(name: "E-Commerce Core Services")
ecommerce.update!(admin: acme_user)

audit = Project.find_or_create_by!(name: "Packablock Audit Project")
audit.update!(admin: admin)

# Link repositories by ID
ProjectRepository.find_or_create_by!(repo_id: 1) { |pr| pr.project = defense }
ProjectRepository.find_or_create_by!(repo_id: 2) { |pr| pr.project = audit }
ProjectRepository.find_or_create_by!(repo_id: 3) { |pr| pr.project = ecommerce }
ProjectRepository.find_or_create_by!(repo_id: 4) { |pr| pr.project = ecommerce }
