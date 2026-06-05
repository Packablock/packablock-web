class Project < ApplicationRecord
  belongs_to :admin, optional: true
  has_many :project_repositories, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
