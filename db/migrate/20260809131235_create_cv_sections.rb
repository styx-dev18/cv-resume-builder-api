class CreateCvSections < ActiveRecord::Migration[8.1]
  def change
    create_table :cv_sections, id: :uuid do |t|
      t.references :cv, type: :uuid, null: false, foreign_key: true
      t.string :section_type, null: false
      t.string :title
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :cv_sections, [ :cv_id, :position ]
  end
end
