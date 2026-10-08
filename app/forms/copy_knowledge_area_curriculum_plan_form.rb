class CopyKnowledgeAreaCurriculumPlanForm
  include ActiveModel::Model

  attr_accessor :knowledge_area_curriculum_plan_id,
                :knowledge_area_curriculum_plan,
                :curriculum_plan,
                :year,
                :unity_id,
                :grade_id,
                :replace_existing

  validates :knowledge_area_curriculum_plan_id,
            :year,
            :unity_id,
            :grade_id,
            presence: true

  def replace_existing?
    replace_existing.to_s == 'true' || replace_existing.to_s == '1'
  end
end
