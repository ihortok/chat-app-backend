class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.references :user, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end
  end
end
