class MigrateUsersToOpenidConnect < ActiveRecord::Migration
  def change

    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :thumbnail, :text


    reversible do |dir|
      dir.up do
        # add a CHECK constraint
        execute <<-SQL
          UPDATE users 
          SET provider='openid_connect'
          WHERE provider='saml' 
        SQL
      end
      dir.down do
        execute <<-SQL
          UPDATE users 
          SET provider='saml'
          WHERE provider='openid_connect' 
          
        SQL
      end
    end
 
      

  end
end
