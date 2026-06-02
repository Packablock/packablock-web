class CreateProjectRepositories < ActiveRecord::Migration[8.0]
  def change
    create_table :project_repositories do |t|
      t.integer :repo_id
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
