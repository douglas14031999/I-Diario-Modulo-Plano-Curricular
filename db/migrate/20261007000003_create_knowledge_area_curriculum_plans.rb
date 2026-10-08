class CreateKnowledgeAreaCurriculumPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :knowledge_area_curriculum_plans do |t|
      t.references :curriculum_plan, null: false, index: { unique: true }, foreign_key: true
      t.text :experience_fields

      t.timestamps
    end

    create_table :knowledge_area_curriculum_plan_knowledge_areas do |t|
      t.references :knowledge_area_curriculum_plan, null: false, index: { name: :idx_kacpka_on_plan_id }
      t.references :knowledge_area, null: false, index: { name: :idx_kacpka_on_area_id }

      t.timestamps
    end

    add_foreign_key :knowledge_area_curriculum_plan_knowledge_areas,
                    :knowledge_area_curriculum_plans,
                    name: :fk_kacpka_on_curr_plan
    add_foreign_key :knowledge_area_curriculum_plan_knowledge_areas,
                    :knowledge_areas,
                    name: :fk_kacpka_on_area
  end
end
