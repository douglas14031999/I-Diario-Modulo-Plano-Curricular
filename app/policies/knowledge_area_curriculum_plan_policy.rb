class KnowledgeAreaCurriculumPlanPolicy < ApplicationPolicy
  def index?
    @user.can_show?(:knowledge_area_curriculum_plans)
  end

  def show?
    index?
  end

  def create?
    @user.can_change?(:knowledge_area_curriculum_plans)
  end

  def new?
    create?
  end

  def update?
    @user.can_change?(:knowledge_area_curriculum_plans)
  end

  def edit?
    update?
  end

  def destroy?
    @user.can_change?(:knowledge_area_curriculum_plans)
  end

  def copy?
    return false unless index?
    @user.teacher? || @user.can_change?(:copy_knowledge_area_curriculum_plan) || @user.can_change?(:copy_knowledge_area_teaching_plan)
  end

  def do_copy?
    copy?
  end
end
