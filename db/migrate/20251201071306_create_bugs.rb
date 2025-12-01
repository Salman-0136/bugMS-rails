class CreateBugs < ActiveRecord::Migration[7.2]
  def change
    create_table :bugs do |t|
      t.string :title
      t.text :description
      t.date :due_date
      t.integer :time_lapse
      t.integer :priority
      t.integer :severity
      t.integer :status
      t.integer :bug_type

      t.timestamps
    end
  end
end
