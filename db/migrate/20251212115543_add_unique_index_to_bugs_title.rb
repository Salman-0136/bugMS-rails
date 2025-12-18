class AddUniqueIndexToBugsTitle < ActiveRecord::Migration[7.0]
  def up
    # Step 1: Delete all assignments for duplicate bugs
    execute <<~SQL
      DELETE FROM bug_assignments
      WHERE bug_id IN (
        SELECT id FROM bugs
        WHERE id NOT IN (
          SELECT MIN(id)
          FROM bugs
          GROUP BY title
        )
      );
    SQL

    # Step 2: Delete duplicate bugs
    execute <<~SQL
      DELETE FROM bugs
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM bugs
        GROUP BY title
      );
    SQL

    # Step 3: Add unique index
    add_index :bugs, :title, unique: true
  end

  def down
    remove_index :bugs, :title
  end
end
