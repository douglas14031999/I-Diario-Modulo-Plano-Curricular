class ContentsCurriculumPlan < ApplicationRecord
  include Audit
  audited except: [:curriculum_plan_id],
          allow_mass_assignment: true,
          associated_with: [:curriculum_plan, :content]

  belongs_to :curriculum_plan
  belongs_to :content

  before_save :set_position

  private

  def set_position
    return unless curriculum_plan&.contents_created_at_position.present? && content.present?

    self.position = curriculum_plan.contents_created_at_position[content.id]
  end
end
