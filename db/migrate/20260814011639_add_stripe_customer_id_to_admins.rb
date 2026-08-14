class AddStripeCustomerIdToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :stripe_customer_id, :string
  end
end
