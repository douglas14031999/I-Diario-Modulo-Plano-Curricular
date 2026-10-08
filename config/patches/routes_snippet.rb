# Adicione ao bloco de rotas de config/routes.rb:
resources :discipline_curriculum_plans, concerns: :history
get '/discipline_curriculum_plans/:id/copy', as: :copy_discipline_curriculum_plans, to: 'discipline_curriculum_plans#copy'
post '/discipline_curriculum_plans/:id/copy', as: :copy_discipline_curriculum_plans, to: 'discipline_curriculum_plans#do_copy'

resources :knowledge_area_curriculum_plans, concerns: :history
get '/knowledge_area_curriculum_plans/:id/copy', as: :copy_knowledge_area_curriculum_plans, to: 'knowledge_area_curriculum_plans#copy'
post '/knowledge_area_curriculum_plans/:id/copy', as: :copy_knowledge_area_curriculum_plans, to: 'knowledge_area_curriculum_plans#do_copy'
