class AddBugsCountToProjects < ActiveRecord::Migration[7.2]
  def change
    add_column :projects, :bugs_count, :integer
  end
end
