class ObjectivesCurriculumPlan < ApplicationRecord
  include Audit
  audited except: [:curriculum_plan_id],
          allow_mass_assignment: true,
          associated_with: [:curriculum_plan, :objective]

  belongs_to :curriculum_plan
  belongs_to :objective

  before_save :set_position

  private

  def set_position
    return unless curriculum_plan&.objectives_created_at_position.present? && objective.present?

    self.position = curriculum_plan.objectives_created_at_position[objective.id]
  end
end
