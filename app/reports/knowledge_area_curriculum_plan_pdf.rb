class KnowledgeAreaCurriculumPlanPdf < BaseReport
  def self.build(entity_configuration, knowledge_area_curriculum_plan)
    new.build(entity_configuration, knowledge_area_curriculum_plan)
  end

  def build(entity_configuration, knowledge_area_curriculum_plan)
    @entity_configuration = entity_configuration
    @knowledge_area_curriculum_plan = knowledge_area_curriculum_plan
    attributes

    if @display_header_on_all_reports_pages
      header
      body
    else
      bounding_box([0, cursor], width: bounds.width, height: bounds.height - GAP) do
        header
        body
      end
    end

    footer

    self
  end

  private

  def header
    header_cell = make_cell(
      content: 'Plano Curricular por Área de Conhecimento',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )

    begin
      entity_logo_cell = make_cell(
        image: @entity_configuration.cached_logo,
        fit: [50, 50],
        width: 70,
        rowspan: 4,
        position: :center,
        vposition: :center
      )
    rescue
      entity_logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''
    unity_name = curriculum_plan.unity ? curriculum_plan.unity.name : 'Toda a Rede'

    entity_organ_and_unity_cell = make_cell(
      content: "#{entity_name}\n#{organ_name}\n#{unity_name}",
      size: 12,
      leading: 1.5,
      align: :center,
      valign: :center,
      rowspan: 4,
      padding: [6, 0, 8, 0]
    )

    table_data = [
      [header_cell],
      [
        entity_logo_cell,
        entity_organ_and_unity_cell
      ]
    ]

    page_header do
      table(table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def attributes
    general_information_attribute
    class_plan_attribute
    unity_attribute
    knowledge_area_attribute
    classroom_attribute
    author_attribute
    year_attribute
    period_attribute
  end

  def general_information
    general_information_table_data = [
      [@general_information_header_cell],
      [@unity_header],
      [@unity_cell],
      [@knowledge_area_header, @classroom_header],
      [@knowledge_area_cell, @classroom_cell],
      [@author_header, @year_header, @period_header],
      [@author_cell, @year_cell, @period_cell]
    ]

    table(general_information_table_data, width: bounds.width) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    move_down GAP
  end

  def class_plan
    class_plan_table_data = [
      [@class_plan_header_cell]
    ]

    table(class_plan_table_data, width: bounds.width, cell_style: { inline_format: true }) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    experience_fields = @knowledge_area_curriculum_plan.experience_fields.presence
    content = curriculum_plan.contents.present? ? curriculum_plan.contents_ordered.map(&:to_s).join("\n ") : '-'
    objectives = curriculum_plan.objectives.present? ? curriculum_plan.objectives_ordered.map(&:to_s).join("\n ") : '-'
    methodology = ActionController::Base.helpers.strip_tags(curriculum_plan.methodology).presence || '-'
    evaluation = ActionController::Base.helpers.strip_tags(curriculum_plan.evaluation).presence || '-'
    references = ActionController::Base.helpers.strip_tags(curriculum_plan.references).presence || '-'

    experience_fields_label = 'Campos de Experiência'
    contents_label = 'Conteúdos Curriculares'
    objectives_label = 'Objetivos de Aprendizagem'
    methodology_label = 'Metodologia Sugerida'
    evaluation_label = 'Critérios de Avaliação'
    references_label = 'Referências / Bibliografia'

    text_box_truncate(experience_fields_label, experience_fields) if experience_fields
    text_box_truncate(contents_label, content)
    text_box_truncate(objectives_label, objectives)
    text_box_truncate(methodology_label, methodology)
    text_box_truncate(evaluation_label, evaluation)
    text_box_truncate(references_label, references)
  end

  def body
    page_content do
      general_information
      class_plan
    end
  end

  def general_information_attribute
    @general_information_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 7
    )
  end

  def class_plan_attribute
    @class_plan_header_cell = make_cell(
      content: 'Plano Curricular',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 4
    )
  end

  def unity_attribute
    @unity_header = make_cell(
      content: 'Escola',
      size: 8,
      font_style: :bold,
      borders: [:left, :right, :top],
      padding: [2, 2, 4, 4],
      colspan: 7
    )
    @unity_cell = make_cell(
      content: curriculum_plan.unity ? curriculum_plan.unity.name : 'Toda a Rede',
      size: 10,
      borders: [:bottom, :left, :right],
      padding: [0, 2, 4, 4],
      colspan: 7
    )
  end

  def knowledge_area_attribute
    descriptions = @knowledge_area_curriculum_plan.knowledge_areas.map(&:to_s).join(', ')

    @knowledge_area_header = make_cell(
      content: 'Áreas de Conhecimento',
      size: 8,
      font_style: :bold,
      borders: [:top, :left, :right],
      padding: [2, 2, 4, 4],
      colspan: 3
    )
    @knowledge_area_cell = make_cell(
      content: descriptions.presence || '-',
      size: 10,
      borders: [:bottom, :left, :right],
      padding: [0, 2, 4, 4],
      colspan: 3
    )
  end

  def classroom_attribute
    @classroom_header = make_cell(
      content: 'Série/Ano',
      size: 8,
      font_style: :bold,
      borders: [:left, :right, :top],
      padding: [2, 2, 4, 4],
      colspan: 4
    )
    @classroom_cell = make_cell(
      content: curriculum_plan.grade.description,
      size: 10,
      borders: [:bottom, :left, :right],
      padding: [0, 2, 4, 4],
      colspan: 4
    )
  end

  def author_attribute
    text = curriculum_plan.created_by_user ? curriculum_plan.created_by_user.name : 'Secretaria / Rede'

    @author_header = make_cell(
      content: 'Cadastrado por',
      size: 8,
      font_style: :bold,
      borders: [:left, :right, :top],
      padding: [2, 2, 4, 4],
      colspan: 3
    )
    @author_cell = make_cell(
      content: text,
      size: 10,
      borders: [:bottom, :left, :right],
      padding: [0, 2, 4, 4],
      colspan: 3
    )
  end

  def year_attribute
    @year_header = make_cell(
      content: 'Ano',
      size: 8,
      font_style: :bold,
      borders: [:left, :right, :top],
      padding: [2, 2, 4, 4],
      colspan: 2
    )
    @year_cell = make_cell(
      content: curriculum_plan.year.to_s,
      size: 10,
      borders: [:bottom, :left, :right],
      padding: [0, 2, 4, 4],
      colspan: 2
    )
  end

  def period_attribute
    @period_header = make_cell(
      content: 'Período escolar',
      size: 8,
      font_style: :bold,
      borders: [:left, :right, :top],
      padding: [2, 2, 4, 4],
      colspan: 2
    )
    @period_cell = make_cell(
      content: period_attribute_text,
      size: 10,
      borders: [:bottom, :left, :right],
      padding: [0, 2, 4, 4],
      colspan: 2
    )
  end

  def period_attribute_text
    return curriculum_plan.school_term_type.to_s if curriculum_plan.yearly?

    curriculum_plan.school_term_type_step_humanize.presence || curriculum_plan.school_term_type_step.to_s
  end

  def curriculum_plan
    @curriculum_plan ||= @knowledge_area_curriculum_plan.curriculum_plan
  end
end
