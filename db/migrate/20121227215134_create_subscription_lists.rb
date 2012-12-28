class CreateSubscriptionLists < ActiveRecord::Migration
  def change
    create_table :subscription_lists do |t|
      t.integer    :mill33_list_id, :unique => true
      t.string     :snhu_code, :unique => true
      t.timestamps
    end

    add_index :subscription_lists, :snhu_code
  end
end
