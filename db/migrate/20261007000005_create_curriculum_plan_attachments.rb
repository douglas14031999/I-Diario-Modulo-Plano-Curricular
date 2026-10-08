class CreateCurriculumPlanAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :curriculum_plan_attachments do |t|
      t.references :curriculum_plan, index: true, foreign_key: true
      t.string :attachment
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at

      t.timestamps null: false
    end
  end
end
