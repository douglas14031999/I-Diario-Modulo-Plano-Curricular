class KnowledgeAreaCurriculumPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :fetch_options, only: [:new, :create, :edit, :update, :show]
  before_action :yearly_term_type_id, only: [:show, :edit, :new]
  before_action :setup_default_filters, only: [:index]
  before_action :fetch_grades, only: [:index]
  before_action :school_term_type, only: [:index]
  before_action :school_term_type_step, only: [:index]

  def index
    @knowledge_area_curriculum_plans = fetch_curriculum_plans

    authorize @knowledge_area_curriculum_plans, :index?
  end

  def show
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.find(params[:id])
    authorize @knowledge_area_curriculum_plan, :show?

    respond_with @knowledge_area_curriculum_plan do |format|
      format.pdf do
        knowledge_area_curriculum_plan_pdf = KnowledgeAreaCurriculumPlanPdf.build(
          current_entity_configuration,
          @knowledge_area_curriculum_plan
        )
        send_pdf('plano_curricular_area', knowledge_area_curriculum_plan_pdf.render)
      end
      format.html
    end
  end

  def new
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.new
    @knowledge_area_curriculum_plan.build_curriculum_plan(
      year: current_school_calendar&.year || Date.current.year
    )

    authorize @knowledge_area_curriculum_plan, :new?
  end

  def create
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.new(resource_params)
    @knowledge_area_curriculum_plan.curriculum_plan.created_by_user = current_user
    @knowledge_area_curriculum_plan.curriculum_plan.content_ids = content_ids
    @knowledge_area_curriculum_plan.curriculum_plan.objective_ids = objective_ids
    set_knowledge_areas
    sanitize_text_fields(@knowledge_area_curriculum_plan.curriculum_plan)

    authorize @knowledge_area_curriculum_plan, :create?

    if @knowledge_area_curriculum_plan.save
      redirect_to knowledge_area_curriculum_plans_path, notice: 'Plano Curricular por área cadastrado com sucesso.'
    else
      yearly_term_type_id
      fetch_options
      render :new
    end
  end

  def edit
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.find(params[:id])
    authorize @knowledge_area_curriculum_plan, :edit?
  end

  def update
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.find(params[:id])
    authorize @knowledge_area_curriculum_plan, :update?

    @knowledge_area_curriculum_plan.assign_attributes(resource_params)
    @knowledge_area_curriculum_plan.curriculum_plan.content_ids = content_ids
    @knowledge_area_curriculum_plan.curriculum_plan.objective_ids = objective_ids
    set_knowledge_areas
    sanitize_text_fields(@knowledge_area_curriculum_plan.curriculum_plan)

    if @knowledge_area_curriculum_plan.save
      redirect_to knowledge_area_curriculum_plans_path, notice: 'Plano Curricular por área atualizado com sucesso.'
    else
      yearly_term_type_id
      fetch_options
      render :edit
    end
  end

  def destroy
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.find(params[:id])
    authorize @knowledge_area_curriculum_plan, :destroy?

    @knowledge_area_curriculum_plan.destroy
    redirect_to knowledge_area_curriculum_plans_path, notice: 'Plano Curricular por área excluído com sucesso.'
  end

  def copy
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.find(params[:id])
    authorize @knowledge_area_curriculum_plan, :copy?

    @copy_form = CopyKnowledgeAreaCurriculumPlanForm.new(
      knowledge_area_curriculum_plan_id: @knowledge_area_curriculum_plan.id,
      knowledge_area_curriculum_plan: @knowledge_area_curriculum_plan,
      curriculum_plan: @knowledge_area_curriculum_plan.curriculum_plan,
      year: @knowledge_area_curriculum_plan.curriculum_plan.year,
      grade_id: @knowledge_area_curriculum_plan.curriculum_plan.grade_id,
      unity_id: current_unity&.id
    )

    fetch_copy_options
  end

  def do_copy
    @knowledge_area_curriculum_plan = KnowledgeAreaCurriculumPlan.find(params[:id])
    authorize @knowledge_area_curriculum_plan, :do_copy?

    form_params = params[:copy_knowledge_area_curriculum_plan_form] || {}
    target_teacher = current_teacher || current_user.teacher

    unless target_teacher
      flash[:error] = 'Apenas professores vinculados podem realizar a cópia para seu Plano de Ensino.'
      return redirect_to knowledge_area_curriculum_plans_path
    end

    begin
      new_plan = CopyKnowledgeAreaCurriculumPlanToTeachingPlanService.call(
        knowledge_area_curriculum_plan_id: @knowledge_area_curriculum_plan.id,
        year: form_params[:year] || @knowledge_area_curriculum_plan.curriculum_plan.year,
        unity_id: form_params[:unity_id],
        grade_id: form_params[:grade_id],
        teacher: target_teacher,
        replace_existing: form_params[:replace_existing].to_s == '1' || form_params[:replace_existing].to_s == 'true'
      )

      redirect_to knowledge_area_teaching_plan_path(new_plan),
                  notice: 'Plano Curricular por área copiado com sucesso para o seu Plano de Ensino!'
    rescue CopyKnowledgeAreaCurriculumPlanToTeachingPlanService::ExistingTeachingPlanConflictError => e
      flash[:alert] = e.message
      @conflict_detected = true
      @copy_form = CopyKnowledgeAreaCurriculumPlanForm.new(
        knowledge_area_curriculum_plan_id: @knowledge_area_curriculum_plan.id,
        knowledge_area_curriculum_plan: @knowledge_area_curriculum_plan,
        curriculum_plan: @knowledge_area_curriculum_plan.curriculum_plan,
        year: form_params[:year],
        unity_id: form_params[:unity_id],
        grade_id: form_params[:grade_id],
        replace_existing: form_params[:replace_existing]
      )
      fetch_copy_options
      render :copy
    rescue => e
      flash[:error] = e.message
      @copy_form = CopyKnowledgeAreaCurriculumPlanForm.new(
        knowledge_area_curriculum_plan_id: @knowledge_area_curriculum_plan.id,
        knowledge_area_curriculum_plan: @knowledge_area_curriculum_plan,
        curriculum_plan: @knowledge_area_curriculum_plan.curriculum_plan,
        year: form_params[:year],
        unity_id: form_params[:unity_id],
        grade_id: form_params[:grade_id],
        replace_existing: form_params[:replace_existing]
      )
      fetch_copy_options
      render :copy
    end
  end

  private

  def setup_default_filters
    return if params.key?(:filter)

    default_filters = {}
    default_year = current_user&.current_school_year.presence || current_school_calendar&.year
    default_filters[:by_year] = default_year.to_s if default_year.present?

    params[:filter] = ActionController::Parameters.new(default_filters).permit! if default_filters.present?
  end

  def fetch_grades
    if current_user&.teacher? && current_teacher.present? && current_unity.present?
      fetched = TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
      if fetched && fetched[:classroom_grades].present?
        grade_ids = fetched[:classroom_grades].map(&:grade_id).compact.uniq
        @teacher_grades = Grade.where(id: grade_ids).ordered
        @grades = @teacher_grades
      end
    end

    @grades ||= Grade.ordered
  end

  def fetch_curriculum_plans
    plans = KnowledgeAreaCurriculumPlan.includes(
      :knowledge_areas,
      curriculum_plan: [:unity, :grade, :school_term_type, :school_term_type_step]
    )

    if params[:filter].present?
      plans = plans.by_year(params[:filter][:by_year]) if params[:filter][:by_year].present?
      if params[:filter][:by_grade].present?
        plans = plans.by_grade(params[:filter][:by_grade])
      elsif current_user&.teacher?
        plans = @teacher_grades.present? ? plans.by_grade(@teacher_grades.map(&:id)) : plans.none
      end
      plans = plans.by_knowledge_area(params[:filter][:by_knowledge_area]) if params[:filter][:by_knowledge_area].present?
      plans = plans.by_school_term_type_id(params[:filter][:by_school_term_type_id]) if params[:filter][:by_school_term_type_id].present?
      plans = plans.by_school_term_type_step_id(params[:filter][:by_school_term_type_step_id]) if params[:filter][:by_school_term_type_step_id].present?
      plans = plans.by_school_term_type_step_id(params[:filter][:by_step]) if params[:filter][:by_step].present?
    elsif current_user&.teacher?
      plans = @teacher_grades.present? ? plans.by_grade(@teacher_grades.map(&:id)) : plans.none
    end

    apply_scopes(plans.order_by_grades.order('curriculum_plans.year DESC'))
  end

  def school_term_type
    @school_term_type ||= SchoolTermType.to_select2(
      current_user&.current_school_year.presence || current_school_calendar&.year,
      current_user&.current_unity_id
    ).to_json
  end

  def school_term_type_step
    @school_term_type_step ||= SchoolTermTypeStep.to_select2(
      current_user&.current_school_year.presence || current_school_calendar&.year,
      current_user&.current_unity_id
    ).to_json
  end

  def resource_params
    params.require(:knowledge_area_curriculum_plan).permit(
      :experience_fields,
      knowledge_area_ids: [],
      curriculum_plan_attributes: [
        :id,
        :year,
        :unity_id,
        :grade_id,
        :school_term_type_id,
        :school_term_type_step_id,
        :methodology,
        :evaluation,
        :references,
        :opinion,
        :validated,
        curriculum_plan_attachments_attributes: [:id, :attachment, :_destroy]
      ]
    )
  end

  def set_knowledge_areas
    raw_ids = params[:knowledge_area_ids] || params.dig(:knowledge_area_curriculum_plan, :knowledge_area_ids)
    return unless raw_ids.present?

    area_ids = if raw_ids.is_a?(Array)
                 raw_ids.reject(&:blank?).map(&:to_i)
               else
                 raw_ids.to_s.split(',').reject(&:blank?).map(&:to_i)
               end

    @knowledge_area_curriculum_plan.knowledge_areas = KnowledgeArea.where(id: area_ids)
  end

  def content_ids
    cp_params = params[:knowledge_area_curriculum_plan].try(:[], :curriculum_plan_attributes) || {}
    param_content_ids = cp_params[:content_ids] || params[:content_ids].to_s.split(',').reject(&:blank?) || []
    content_descriptions = cp_params[:content_descriptions] || []

    @knowledge_area_curriculum_plan.curriculum_plan.contents_created_at_position = {}

    param_content_ids.each_with_index do |content_id, index|
      @knowledge_area_curriculum_plan.curriculum_plan.contents_created_at_position[content_id.to_i] = index
    end

    new_contents_ids = content_descriptions.each_with_index.map do |description, index|
      content = Content.find_or_create_by!(description: description)
      @knowledge_area_curriculum_plan.curriculum_plan.contents_created_at_position[content.id] =
        param_content_ids.size + index

      content.id
    end

    @ordered_content_ids = param_content_ids.map(&:to_i) + new_contents_ids
  end

  def objective_ids
    cp_params = params[:knowledge_area_curriculum_plan].try(:[], :curriculum_plan_attributes) || {}
    param_objective_ids = cp_params[:objective_ids] || params[:objective_ids].to_s.split(',').reject(&:blank?) || []
    objective_descriptions = cp_params[:objective_descriptions] || []

    @knowledge_area_curriculum_plan.curriculum_plan.objectives_created_at_position = {}

    param_objective_ids.each_with_index do |objective_id, index|
      @knowledge_area_curriculum_plan.curriculum_plan.objectives_created_at_position[objective_id.to_i] = index
    end

    new_objectives_ids = objective_descriptions.each_with_index.map do |description, index|
      objective = Objective.find_or_create_by!(description: description)
      @knowledge_area_curriculum_plan.curriculum_plan.objectives_created_at_position[objective.id] =
        param_objective_ids.size + index

      objective.id
    end

    @ordered_objective_ids = param_objective_ids.map(&:to_i) + new_objectives_ids
  end

  def contents
    @contents = []

    return @contents if @knowledge_area_curriculum_plan.nil? || @knowledge_area_curriculum_plan.curriculum_plan.nil? || @knowledge_area_curriculum_plan.curriculum_plan.content_ids.blank?

    @contents = if @ordered_content_ids.present?
                  Content.find_and_order_by_id_sequence(@ordered_content_ids)
                else
                  @knowledge_area_curriculum_plan.curriculum_plan.contents_ordered
                end

    @contents = @contents.each { |content| content.is_editable = true }.uniq
  end
  helper_method :contents

  def objectives
    @objectives = []

    return @objectives if @knowledge_area_curriculum_plan.nil? || @knowledge_area_curriculum_plan.curriculum_plan.nil? || @knowledge_area_curriculum_plan.curriculum_plan.objective_ids.blank?

    @objectives = if @ordered_objective_ids.present?
                    Objective.find_and_order_by_id_sequence(@ordered_objective_ids)
                  else
                    @knowledge_area_curriculum_plan.curriculum_plan.objectives_ordered
                  end

    @objectives = @objectives.each { |objective| objective.is_editable = true }.uniq
  end
  helper_method :objectives

  def sanitize_text_fields(plan)
    return unless plan.present?

    plan.methodology = ActionController::Base.helpers.sanitize(plan.methodology, tags: %w[b br i u p])
    plan.evaluation = ActionController::Base.helpers.sanitize(plan.evaluation, tags: %w[b br i u p])
    plan.references = ActionController::Base.helpers.sanitize(plan.references, tags: %w[b br i u p])
  end

  def fetch_options
    @grades = Grade.to_select
    grade_id = @knowledge_area_curriculum_plan&.curriculum_plan&.grade_id
    if grade_id.present?
      filtered = KnowledgeArea.by_grade(grade_id).ordered
      @knowledge_areas = filtered.presence || KnowledgeArea.ordered
    else
      @knowledge_areas = KnowledgeArea.ordered
    end
    @unities = Unity.ordered
  end

  def fetch_copy_options
    if current_teacher.present?
      @unities = Unity.by_teacher(current_teacher).ordered
      @grades = Grade.to_select
    else
      @unities = Unity.ordered
      @grades = Grade.to_select
    end
    @knowledge_areas = KnowledgeArea.ordered
  end

  def yearly_term_type_id
    @yearly_term_type_id ||= SchoolTermType.find_by(description: 'Anual')&.id
  end
end
