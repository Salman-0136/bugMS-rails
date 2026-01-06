class DropImportExportTables < ActiveRecord::Migration[7.2]
  def up
    # Drop the view first because it might depend on the table logic (though it's a view on bugs)
    execute "DROP VIEW IF EXISTS bug_export_view"
    
    # Drop tables
    drop_table :bug_import_errors if table_exists?(:bug_import_errors)
    drop_table :bug_imports if table_exists?(:bug_imports)
  end

  def down
    # Since this is a cleanup removal, we don't strictly need a 'down' 
    # but for a valid migration we can leave it empty or raise irrevirsible
    raise ActiveRecord::IrreversibleMigration
  end
end
