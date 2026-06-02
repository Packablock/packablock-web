class ProjectRepository < ApplicationRecord
  belongs_to :project

  validates :repo_id, presence: true, uniqueness: true
end
