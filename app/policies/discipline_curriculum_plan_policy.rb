class DisciplineCurriculumPlanPolicy < ApplicationPolicy
  def index?
    @user.can_show?(:discipline_curriculum_plans)
  end

  def show?
    index?
  end

  def create?
    @user.can_change?(:discipline_curriculum_plans)
  end

  def new?
    create?
  end

  def update?
    @user.can_change?(:discipline_curriculum_plans)
  end

  def edit?
    update?
  end

  def destroy?
    @user.can_change?(:discipline_curriculum_plans)
  end

  def copy?
    return false unless index?
    @user.teacher? || @user.can_change?(:copy_discipline_curriculum_plan) || @user.can_change?(:copy_discipline_teaching_plan)
  end

  def do_copy?
    copy?
  end
end
