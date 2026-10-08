class CreateContentsAndObjectivesCurriculumPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :contents_curriculum_plans do |t|
      t.integer :content_id, null: false, index: true
      t.integer :curriculum_plan_id, null: false, index: true
      t.integer :position
    end
    add_foreign_key :contents_curriculum_plans, :contents
    add_foreign_key :contents_curriculum_plans, :curriculum_plans
    add_index :contents_curriculum_plans, [:content_id, :curriculum_plan_id],
              unique: true, name: :idx_contents_curr_plans_uniq

    create_table :objectives_curriculum_plans do |t|
      t.integer :objective_id, null: false, index: true
      t.integer :curriculum_plan_id, null: false, index: true
      t.integer :position
    end
    add_foreign_key :objectives_curriculum_plans, :objectives
    add_foreign_key :objectives_curriculum_plans, :curriculum_plans
    add_index :objectives_curriculum_plans, [:objective_id, :curriculum_plan_id],
              unique: true, name: :idx_obj_curr_plans_uniq
  end
end
