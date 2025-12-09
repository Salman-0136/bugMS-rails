class AddProjectToBugs < ActiveRecord::Migration[7.2]
  def change
    add_reference :bugs, :project, null: true, foreign_key: true
  end
end
