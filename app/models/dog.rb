class Dog < ApplicationRecord
  validates :name, :age, :color, :breed, :owner, presence: true
end
