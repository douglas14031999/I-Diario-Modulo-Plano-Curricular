class KnowledgeAreaCurriculumPlan < ApplicationRecord
  include Audit
  include Translatable

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :curriculum_plan, dependent: :destroy
  has_many :knowledge_area_curriculum_plan_knowledge_areas, dependent: :destroy
  has_many :knowledge_areas, through: :knowledge_area_curriculum_plan_knowledge_areas

  delegate :contents, to: :curriculum_plan
  delegate :objectives, to: :curriculum_plan

  accepts_nested_attributes_for :curriculum_plan

  scope :by_year, ->(year) { joins(:curriculum_plan).where(curriculum_plans: { year: year }) if year.present? }
  scope :by_unity, ->(unity) { joins(:curriculum_plan).where(curriculum_plans: { unity_id: unity }) if unity.present? }
  scope :by_grade, ->(grade) { joins(:curriculum_plan).where(curriculum_plans: { grade_id: grade }) if grade.present? }
  scope :by_school_term_type_id, lambda { |term_type_id|
    joins(:curriculum_plan).where(curriculum_plans: { school_term_type_id: term_type_id }) if term_type_id.present?
  }
  scope :by_school_term_type_step_id, lambda { |step_id|
    joins(:curriculum_plan).where(curriculum_plans: { school_term_type_step_id: step_id }) if step_id.present?
  }
  scope :by_knowledge_area, lambda { |knowledge_area_id|
    joins(:knowledge_area_curriculum_plan_knowledge_areas)
      .where(knowledge_area_curriculum_plan_knowledge_areas: { knowledge_area_id: knowledge_area_id }) if knowledge_area_id.present?
  }
  scope :order_by_school_term_type_step, lambda {
    joins(:curriculum_plan).order('curriculum_plans.school_term_type_step_id IS NULL')
  }
  scope :order_by_grades, lambda {
    joins(curriculum_plan: :grade).order(Grade.arel_table[:description].desc)
  }

  validates :curriculum_plan, presence: true
  validates :knowledge_area_ids, presence: true

  def knowledge_area_ids
    knowledge_areas.collect(&:id).join(',')
  end

  def to_s
    "#{knowledge_areas.map(&:to_s).join(', ')} - #{curriculum_plan.grade if curriculum_plan}"
  end
end
