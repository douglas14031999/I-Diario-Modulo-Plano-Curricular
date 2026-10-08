class CreateCurriculumPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :curriculum_plans do |t|
      t.integer :year, null: false
      t.references :unity, index: true, foreign_key: true
      t.references :grade, null: false, index: true, foreign_key: true
      t.references :school_term_type, null: false, index: true, foreign_key: true
      t.references :school_term_type_step, index: true, foreign_key: true
      t.references :created_by_user, index: true, foreign_key: { to_table: :users }
      t.text :methodology
      t.text :evaluation
      t.text :references
      t.text :opinion
      t.boolean :validated, default: false

      t.timestamps
    end

    add_index :curriculum_plans, [:year, :grade_id], name: :idx_curriculum_plans_year_grade
  end
end
