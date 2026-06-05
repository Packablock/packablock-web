# Seed default administrator account if it doesn't exist
Admin.find_or_create_by!(email: "admin@packablock.com") do |admin|
  admin.password = "admin_secret_token_1234"
  admin.password_confirmation = "admin_secret_token_1234"
  puts " seeded default admin account: admin@packablock.com / admin_secret_token_1234"
end

# Seed default logical projects
defense = Project.find_or_create_by!(name: "Supply Chain Defense Panel")
ecommerce = Project.find_or_create_by!(name: "E-Commerce Core Services")
audit = Project.find_or_create_by!(name: "Packablock Audit Project")

# Link repositories by ID
ProjectRepository.find_or_create_by!(repo_id: 1) { |pr| pr.project = defense }
ProjectRepository.find_or_create_by!(repo_id: 2) { |pr| pr.project = audit }
ProjectRepository.find_or_create_by!(repo_id: 3) { |pr| pr.project = ecommerce }
ProjectRepository.find_or_create_by!(repo_id: 4) { |pr| pr.project = ecommerce }

