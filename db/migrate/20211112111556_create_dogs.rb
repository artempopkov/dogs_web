class CreateDogs < ActiveRecord::Migration[6.1]
  def change
    create_table :dogs do |t|
      t.string :name
      t.string :age
      t.string :color
      t.string :breed
      t.string :owner

      t.timestamps
    end
  end
end
