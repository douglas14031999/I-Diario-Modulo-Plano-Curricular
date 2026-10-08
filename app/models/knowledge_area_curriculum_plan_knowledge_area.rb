class KnowledgeAreaCurriculumPlanKnowledgeArea < ApplicationRecord
  belongs_to :knowledge_area_curriculum_plan
  belongs_to :knowledge_area

  validates :knowledge_area_curriculum_plan, presence: true
  validates :knowledge_area, presence: true
end
