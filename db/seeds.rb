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

# Seed end-user/manager for oven-sh org if it doesn't exist
oven_user = Admin.find_or_initialize_by(email: "manager@oven-sh.com")
oven_user.password = "password123"
oven_user.password_confirmation = "password123"
oven_user.superuser = false
oven_user.save!
puts " seeded oven-sh end-user account: manager@oven-sh.com / password123"

# Seed end-user/manager for rails-org org if it doesn't exist
rails_user = Admin.find_or_initialize_by(email: "manager@rails.org")
rails_user.password = "rails_secret_123"
rails_user.password_confirmation = "rails_secret_123"
rails_user.superuser = false
rails_user.save!
puts " seeded rails-org end-user account: manager@rails.org / rails_secret_123"

# Seed default logical projects
defense = Project.find_or_create_by!(name: "Supply Chain Defense Panel")
defense.update!(admin: admin)

ecommerce = Project.find_or_create_by!(name: "E-Commerce Core Services")
ecommerce.update!(admin: acme_user)

audit = Project.find_or_create_by!(name: "Packablock Audit Project")
audit.update!(admin: admin)

bun_demo = Project.find_or_create_by!(name: "Bun e2e Demo")
bun_demo.update!(admin: oven_user)

rails_demo = Project.find_or_create_by!(name: "Rails e2e Demo")
rails_demo.update!(admin: rails_user)
puts " seeded projects"

# Link repositories by ID
ProjectRepository.find_or_initialize_by(repo_id: 1).update!(project: defense)
ProjectRepository.find_or_initialize_by(repo_id: 2).update!(project: audit)
ProjectRepository.find_or_initialize_by(repo_id: 3).update!(project: ecommerce)
ProjectRepository.find_or_initialize_by(repo_id: 4).update!(project: ecommerce)
ProjectRepository.find_or_initialize_by(repo_id: 5).update!(project: bun_demo)
ProjectRepository.find_or_initialize_by(repo_id: 6).update!(project: rails_demo)
ProjectRepository.find_or_initialize_by(repo_id: 7).update!(project: defense)
puts " linked project repositories"
