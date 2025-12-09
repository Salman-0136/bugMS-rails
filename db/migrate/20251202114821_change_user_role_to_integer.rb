class ChangeUserRoleToInteger < ActiveRecord::Migration[7.1]
  def up
    # Remove old column (string or invalid)
    remove_column :users, :role

    # Add new role column allowing NULL temporarily
    add_column :users, :role, :integer

    # Set default value for all existing users
    User.update_all(role: 0)   # 0 = developer (or your default)

    # Now enforce NOT NULL + default
    change_column :users, :role, :integer, null: false, default: 0
  end

  def down
    add_column :users, :role, :string
    remove_column :users, :role
  end
end
