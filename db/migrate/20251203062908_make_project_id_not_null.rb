class MakeProjectIdNotNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :bugs, :project_id, false
  end
end
