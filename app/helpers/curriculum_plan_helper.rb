module CurriculumPlanHelper
  def curriculum_plan_can_edit?
    current_user.can_change?(:discipline_curriculum_plans)
  end

  def discipline_curriculum_plan_form_url(discipline_curriculum_plan, action_name)
    case action_name
    when 'new', 'create'
      discipline_curriculum_plans_path(locale: I18n.locale)
    when 'edit', 'update'
      discipline_curriculum_plan_path(discipline_curriculum_plan, locale: I18n.locale)
    else
      discipline_curriculum_plans_path(locale: I18n.locale)
    end
  end

  def knowledge_area_curriculum_plan_form_url(knowledge_area_curriculum_plan, action_name)
    case action_name
    when 'new', 'create'
      knowledge_area_curriculum_plans_path(locale: I18n.locale)
    when 'edit', 'update'
      knowledge_area_curriculum_plan_path(knowledge_area_curriculum_plan, locale: I18n.locale)
    else
      knowledge_area_curriculum_plans_path(locale: I18n.locale)
    end
  end

  def curriculum_plan_form_method(action_name)
    case action_name
    when 'new', 'create'
      :post
    else
      :patch
    end
  end
end
