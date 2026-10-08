class CurriculumPlan < ApplicationRecord
  include Audit
  include Translatable

  audited
  has_associated_audits
  acts_as_copy_target

  belongs_to :unity, optional: true
  belongs_to :grade
  belongs_to :school_term_type
  belongs_to :school_term_type_step, optional: true
  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :year, presence: true
  validates :grade, presence: true
  validates :school_term_type, presence: true
  validates :school_term_type_step, presence: { unless: :yearly? }

  has_many :contents_curriculum_plans, dependent: :destroy
  deferred_has_many :contents, through: :contents_curriculum_plans, dependent: :destroy
  has_many :objectives_curriculum_plans, dependent: :destroy
  deferred_has_many :objectives, through: :objectives_curriculum_plans, dependent: :destroy
  has_many :curriculum_plan_attachments, dependent: :destroy

  has_one :discipline_curriculum_plan, dependent: :restrict_with_error
  has_one :knowledge_area_curriculum_plan, dependent: :restrict_with_error

  accepts_nested_attributes_for :contents, allow_destroy: true
  accepts_nested_attributes_for :objectives, allow_destroy: true
  accepts_nested_attributes_for :curriculum_plan_attachments, allow_destroy: true

  before_save :set_default_unity_name

  validate :at_least_one_content_assigned

  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) if unity_id.present? }
  scope :by_grade_id, ->(grade_id) { where(grade_id: grade_id) if grade_id.present? }
  scope :by_year, ->(year) { where(year: year) if year.present? }
  scope :by_school_term_type_id, ->(type_id) { where(school_term_type_id: type_id) if type_id.present? }
  scope :by_school_term_type_step_id, ->(step_id) { where(school_term_type_step_id: step_id) if step_id.present? }

  attr_accessor :grade_ids, :contents_created_at_position, :objectives_created_at_position

  def to_s
    return discipline_curriculum_plan.discipline.to_s if discipline_curriculum_plan
    return knowledge_area_curriculum_plan.knowledge_areas.ordered.first.to_s if knowledge_area_curriculum_plan

    "Plano Curricular #{year}"
  end

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter.tags_to_json(@contents_tags)
    else
      ContentTagConverter.contents_to_json(contents_ordered)
    end
  end

  def contents_ordered
    contents.order('contents_curriculum_plans.position')
  end

  def objectives_ordered
    objectives.order('objectives_curriculum_plans.position')
  end

  def school_term_type_step_humanize
    return '' if yearly?

    school_term_type_step.to_s
  end

  def attachments?
    curriculum_plan_attachments.any?
  end

  def yearly?
    return false unless school_term_type

    SchoolTermType.where("description ILIKE 'Anual%'").where(id: school_term_type.id).exists?
  end

  def unity_name
    if has_attribute?(:unity_name) && read_attribute(:unity_name).present?
      read_attribute(:unity_name)
    else
      unity.present? ? unity.to_s : 'Toda a Rede'
    end
  end

  def unity_humanize
    unity_name
  end

  private

  def set_default_unity_name
    if has_attribute?(:unity_name)
      self.unity_name = unity.present? ? unity.to_s : 'Toda a Rede'
    end
  end

  def at_least_one_content_assigned
    return unless contents_empty?

    errors.add(:contents, :at_least_one_content_assigned)
  end

  def contents_empty?
    contents.empty? || (contents.size == contents.select(&:marked_for_destruction?).size)
  end
end
