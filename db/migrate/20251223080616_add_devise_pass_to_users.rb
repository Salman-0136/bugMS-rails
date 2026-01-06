class AddDevisePassToUsers < ActiveRecord::Migration[7.0]
  def up
    # Add Devise columns
    unless column_exists?(:users, :encrypted_password)
      add_column :users, :encrypted_password, :string, null: false, default: ""
    end

    add_column :users, :reset_password_token, :string unless column_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)
    add_column :users, :remember_created_at, :datetime unless column_exists?(:users, :remember_created_at)

    add_column :users, :sign_in_count, :integer, default: 0, null: false unless column_exists?(:users, :sign_in_count)
    add_column :users, :current_sign_in_at, :datetime unless column_exists?(:users, :current_sign_in_at)
    add_column :users, :last_sign_in_at, :datetime unless column_exists?(:users, :last_sign_in_at)
    add_column :users, :current_sign_in_ip, :string unless column_exists?(:users, :current_sign_in_ip)
    add_column :users, :last_sign_in_ip, :string unless column_exists?(:users, :last_sign_in_ip)

    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)

    # Reset column information for this migration only
    User.reset_column_information

    # Copy password_digest -> encrypted_password safely
    execute <<-SQL.squish
      UPDATE users
      SET encrypted_password = password_digest
      WHERE password_digest IS NOT NULL;
    SQL
  end

  def down
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token)

    remove_column :users, :encrypted_password if column_exists?(:users, :encrypted_password)
    remove_column :users, :reset_password_token if column_exists?(:users, :reset_password_token)
    remove_column :users, :reset_password_sent_at if column_exists?(:users, :reset_password_sent_at)
    remove_column :users, :remember_created_at if column_exists?(:users, :remember_created_at)
    remove_column :users, :sign_in_count if column_exists?(:users, :sign_in_count)
    remove_column :users, :current_sign_in_at if column_exists?(:users, :current_sign_in_at)
    remove_column :users, :last_sign_in_at if column_exists?(:users, :last_sign_in_at)
    remove_column :users, :current_sign_in_ip if column_exists?(:users, :current_sign_in_ip)
    remove_column :users, :last_sign_in_ip if column_exists?(:users, :last_sign_in_ip)
  end
end
