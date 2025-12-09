class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.integer :manager_id

      t.timestamps
    end
  end
end
