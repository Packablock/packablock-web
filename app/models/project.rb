class Project < ApplicationRecord
  has_many :project_repositories, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
