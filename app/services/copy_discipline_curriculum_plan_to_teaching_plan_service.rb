class CopyDisciplineCurriculumPlanToTeachingPlanService
  class ExistingTeachingPlanConflictError < StandardError; end
  class CopyCurriculumPlanError < StandardError; end

  attr_reader :discipline_curriculum_plan_id, :year, :unity_id, :grade_id, :teacher, :replace_existing

  def self.call(*args)
    new(*args).call
  end

  def initialize(
    discipline_curriculum_plan_id:,
    year:,
    unity_id:,
    grade_id:,
    teacher:,
    replace_existing: false
  )
    @discipline_curriculum_plan_id = discipline_curriculum_plan_id
    @year = year
    @unity_id = unity_id
    @grade_id = grade_id
    @teacher = teacher
    @replace_existing = replace_existing
  end

  def call
    discipline_curriculum_plan = DisciplineCurriculumPlan.find(discipline_curriculum_plan_id)
    curriculum_plan = discipline_curriculum_plan.curriculum_plan

    existing_plan = find_existing_plan(discipline_curriculum_plan, curriculum_plan)

    if existing_plan.present? && !replace_existing
      raise ExistingTeachingPlanConflictError,
            'Já existe um Plano de Ensino cadastrado para esta disciplina, turma e etapa. Deseja substituir o existente?'
    end

    ActiveRecord::Base.transaction do
      existing_plan.teaching_plan.destroy if existing_plan.present? && replace_existing

      create_teaching_plan(discipline_curriculum_plan, curriculum_plan)
    end
  end

  private

  def find_existing_plan(discipline_curriculum_plan, curriculum_plan)
    query = DisciplineTeachingPlan.joins(:teaching_plan)
      .where(
        discipline_id: discipline_curriculum_plan.discipline_id,
        teaching_plans: {
          teacher_id: teacher.id,
          unity_id: unity_id,
          grade_id: grade_id,
          year: year,
          school_term_type_id: curriculum_plan.school_term_type_id,
          school_term_type_step_id: curriculum_plan.school_term_type_step_id
        }
      )
    query.first
  end

  def create_teaching_plan(discipline_curriculum_plan, curriculum_plan)
    contents = curriculum_plan.contents_curriculum_plans
    objectives = curriculum_plan.objectives_curriculum_plans

    contents_pos = {}
    content_ids = contents.map.with_index do |item, idx|
      contents_pos[item.content_id] = idx
      item.content_id
    end

    objectives_pos = {}
    objective_ids = objectives.map.with_index do |item, idx|
      objectives_pos[item.objective_id] = idx
      item.objective_id
    end

    teaching_plan = TeachingPlan.new(
      year: year,
      unity_id: unity_id,
      grade_id: grade_id,
      teacher: teacher,
      school_term_type_id: curriculum_plan.school_term_type_id,
      school_term_type_step_id: curriculum_plan.school_term_type_step_id,
      methodology: curriculum_plan.methodology,
      evaluation: curriculum_plan.evaluation,
      references: curriculum_plan.references,
      opinion: curriculum_plan.opinion
    )
    teaching_plan.teacher = teacher
    teaching_plan[:teacher_id] = teacher&.id

    teaching_plan.contents_created_at_position = contents_pos
    teaching_plan.objectives_created_at_position = objectives_pos
    teaching_plan.content_ids = content_ids
    teaching_plan.objective_ids = objective_ids

    dtp = teaching_plan.build_discipline_teaching_plan(
      discipline_id: discipline_curriculum_plan.discipline_id,
      thematic_unit: discipline_curriculum_plan.thematic_unit
    )
    dtp.teacher_id = teacher&.id if dtp.respond_to?(:teacher_id=)

    unless teaching_plan.valid?
      raise CopyCurriculumPlanError, "Erro ao gerar Plano de Ensino: #{teaching_plan.errors.full_messages.join(', ')}"
    end

    teaching_plan.save!
    copy_attachments(curriculum_plan, teaching_plan)
    teaching_plan.discipline_teaching_plan
  end

  def copy_attachments(curriculum_plan, teaching_plan)
    curriculum_plan.curriculum_plan_attachments.each do |cpa|
      next unless cpa.attachment.present?

      if cpa.attachment.file.present? && File.exist?(cpa.attachment.path.to_s)
        File.open(cpa.attachment.path) do |file|
          teaching_plan.teaching_plan_attachments.create!(attachment: file)
        end
      elsif cpa.attachment.url.present?
        teaching_plan.teaching_plan_attachments.create!(remote_attachment_url: cpa.attachment.url)
      end
    end
  end
end
