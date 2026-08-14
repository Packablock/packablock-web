class AddStripeSubscriptionIdToProjectRepositories < ActiveRecord::Migration[8.0]
  def change
    add_column :project_repositories, :stripe_subscription_id, :string
  end
end
