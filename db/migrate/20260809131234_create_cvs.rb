class CreateCvs < ActiveRecord::Migration[8.1]
  def change
    create_table :cvs, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.integer :schema_version, null: false, default: 1

      t.timestamps
    end
  end
end
