class CreateCvSectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cv_section_items, id: :uuid do |t|
      t.references :cv_section, type: :uuid, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      # personalInfo
      t.string :full_name
      t.string :location
      t.string :email
      t.string :phone
      t.string :linkedin
      t.string :github
      t.string :other_link

      # summary
      t.text :content

      # experience (job_title holds ExperienceItem#position; ordering uses
      # the "position" column above)
      t.string :company
      t.string :job_title
      t.string :start_date
      t.string :end_date
      t.boolean :current, null: false, default: false
      t.text :description

      # education
      t.string :school
      t.string :degree
      t.string :honors
      t.string :gpa

      # skills (skills_text holds SkillsItem#skills)
      t.string :category
      t.text :skills_text

      # shared: name (certifications/projects/references),
      # date (certifications/publications/awards)
      t.string :name
      t.string :date

      # languages
      t.string :language
      t.string :proficiency

      # shared: link (projects/publications), title (publications/awards)
      t.string :link
      t.string :title
      t.string :publisher

      # awards
      t.string :issuer

      # references
      t.string :relationship

      # volunteering
      t.string :organization
      t.string :role

      t.timestamps
    end
    add_index :cv_section_items, [ :cv_section_id, :position ]
  end
end
