class DisciplineCurriculumPlan < ApplicationRecord
  include Audit
  include ColumnsLockable
  include Translatable

  not_updatable only: :discipline_id

  audited
  has_associated_audits

  acts_as_copy_target

  belongs_to :curriculum_plan, dependent: :destroy
  belongs_to :discipline

  delegate :contents, to: :curriculum_plan
  delegate :objectives, to: :curriculum_plan

  accepts_nested_attributes_for :curriculum_plan

  scope :by_year, ->(year) { joins(:curriculum_plan).where(curriculum_plans: { year: year }) if year.present? }
  scope :by_unity, ->(unity) { joins(:curriculum_plan).where(curriculum_plans: { unity_id: unity }) if unity.present? }
  scope :by_grade, ->(grade) { joins(:curriculum_plan).where(curriculum_plans: { grade_id: grade }) if grade.present? }
  scope :by_discipline, ->(discipline) { where(discipline_id: discipline) if discipline.present? }
  scope :by_school_term_type_id, lambda { |term_type_id|
    joins(:curriculum_plan).where(curriculum_plans: { school_term_type_id: term_type_id }) if term_type_id.present?
  }
  scope :by_school_term_type_step_id, lambda { |step_id|
    joins(:curriculum_plan).where(curriculum_plans: { school_term_type_step_id: step_id }) if step_id.present?
  }
  scope :order_by_school_term_type_step, lambda {
    joins(:curriculum_plan).order('curriculum_plans.school_term_type_step_id IS NULL')
  }
  scope :order_by_grades, -> { joins(curriculum_plan: :grade).order(Grade.arel_table[:description].desc) }

  validates :curriculum_plan, presence: true
  validates :discipline, presence: true

  def to_s
    "#{discipline} - #{curriculum_plan.grade if curriculum_plan}"
  end
end
