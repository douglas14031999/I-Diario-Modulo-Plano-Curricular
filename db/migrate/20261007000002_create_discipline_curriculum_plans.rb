class CreateDisciplineCurriculumPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :discipline_curriculum_plans do |t|
      t.references :curriculum_plan, null: false, index: { unique: true }, foreign_key: true
      t.references :discipline, null: false, index: true, foreign_key: true
      t.text :thematic_unit

      t.timestamps
    end

    add_index :discipline_curriculum_plans, [:discipline_id, :curriculum_plan_id],
              name: :idx_disc_curr_plans_on_disc_and_plan
  end
end
