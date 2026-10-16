class AddColumnsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :parent_first_name, :string
    add_column :users, :parent_last_name, :string
    add_column :users, :kid_name, :string    
  end
end
