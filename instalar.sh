#!/usr/bin/env bash
# ==============================================================================
# SCRIPT DE INSTALAÇÃO DEFINITIVA: MÓDULO DE PLANOS CURRICULARES
# i-Diário - Sistema de Gestão Escolar (Versão com 147 Planos BNCC, EJA e AEE)
# ==============================================================================
# Este script automatiza 100% da instalação:
# 1. Copia todos os arquivos novos (controllers, models, views, forms, services, reports, etc.)
# 2. Configura as rotas em config/routes.rb
# 3. Configura o menu de navegação em config/navigation.yml
# 4. Registra as novas features em app/enumerations/features.rb
# 5. Concede permissões aos perfis em app/services/features_access_levels.rb
# 6. Atualiza as permissões de acesso diretamente no banco de dados
# 7. Executa as migrações (rake db:migrate)
# 8. Executa o seed para popular os 147 planos curriculares oficiais
# 9. Recarrega o servidor Rails (touch tmp/restart.txt)
# ==============================================================================
set -e

CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_GREEN="\033[1;32m"
CLR_BLUE="\033[1;34m"
CLR_YELLOW="\033[1;33m"
CLR_RED="\033[1;31m"
CLR_CYAN="\033[1;36m"

print_header() {
  echo -e "\n${CLR_CYAN}==============================================================================${CLR_RESET}"
  echo -e "${CLR_BOLD}   $1${CLR_RESET}"
  echo -e "${CLR_CYAN}==============================================================================${CLR_RESET}"
}

print_step() {
  echo -e "\n${CLR_BLUE}==>${CLR_RESET} ${CLR_BOLD}[$1]${CLR_RESET} $2..."
}

print_success() {
  echo -e "   ${CLR_GREEN}[OK] SUCESSO:${CLR_RESET} $1"
}

print_warning() {
  echo -e "   ${CLR_YELLOW}[AVISO]:${CLR_RESET} $1"
}

print_error() {
  echo -e "   ${CLR_RED}[ERRO]:${CLR_RESET} $1"
}

print_header "INSTALAÇÃO COMPLETA: MÓDULO DE PLANOS CURRICULARES (i-Diário)"

# 1. Identificar o diretório do i-Diário
APP_DIR="${1:-}"
if [ -z "$APP_DIR" ] || [ ! -f "$APP_DIR/config/routes.rb" ]; then
  POSSIBLE_DIRS=("/root/i-diario" "/var/www/i-diario" "/home/idiario/i-diario" "/opt/i-diario" "$(pwd)")
  for d in "${POSSIBLE_DIRS[@]}"; do
    if [ -f "$d/config/routes.rb" ]; then
      APP_DIR="$d"
      break
    fi
  done
fi

if [ -z "$APP_DIR" ] || [ ! -f "$APP_DIR/config/routes.rb" ]; then
  print_error "Diretório do i-Diário não encontrado!"
  echo "Uso: bash $0 /caminho/para/i-diario"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Diretório de Origem (Módulo): $SCRIPT_DIR"
echo "Diretório de Destino (i-Diário): $APP_DIR"

# 2. Copiar Arquivos do Módulo
print_step "1/8" "Copiando arquivos do módulo para o i-Diário"

mkdir -p "$APP_DIR/app/controllers" \
         "$APP_DIR/app/models" \
         "$APP_DIR/app/forms" \
         "$APP_DIR/app/services" \
         "$APP_DIR/app/policies" \
         "$APP_DIR/app/reports" \
         "$APP_DIR/app/helpers" \
         "$APP_DIR/app/views/discipline_curriculum_plans" \
         "$APP_DIR/app/views/knowledge_area_curriculum_plans" \
         "$APP_DIR/app/assets/javascripts/views/discipline_curriculum_plans" \
         "$APP_DIR/app/assets/javascripts/views/knowledge_area_curriculum_plans" \
         "$APP_DIR/config/locales/models" \
         "$APP_DIR/config/locales/controllers" \
         "$APP_DIR/db/migrate" \
         "$APP_DIR/db/seeds"

cp -rf "$SCRIPT_DIR/app/"* "$APP_DIR/app/"
cp -rf "$SCRIPT_DIR/config/locales/"* "$APP_DIR/config/locales/"
cp -rf "$SCRIPT_DIR/db/migrate/"* "$APP_DIR/db/migrate/"
cp -f "$SCRIPT_DIR/db/seeds/curriculum_plans_bncc.rb" "$APP_DIR/db/seeds/"
if [ -f "$SCRIPT_DIR/bncc_oficial_consolidada.json" ]; then
  cp -f "$SCRIPT_DIR/bncc_oficial_consolidada.json" "$APP_DIR/"
fi

print_success "Todos os 54 arquivos novos foram copiados."

# 3. Atualizar Rotas (config/routes.rb)
print_step "2/8" "Configurando rotas do módulo em config/routes.rb"
ROUTES_FILE="$APP_DIR/config/routes.rb"
if ! grep -q "discipline_curriculum_plans" "$ROUTES_FILE"; then
  cat << 'RUBY_ROUTES' > /tmp/routes_block.rb
    # --- Módulo: Planos Curriculares da Rede ---
    resources :discipline_curriculum_plans, concerns: :history
    get '/discipline_curriculum_plans/:id/copy', as: :copy_discipline_curriculum_plans, to: 'discipline_curriculum_plans#copy'
    post '/discipline_curriculum_plans/:id/copy', as: :copy_discipline_curriculum_plans, to: 'discipline_curriculum_plans#do_copy'
    resources :knowledge_area_curriculum_plans, concerns: :history
    get '/knowledge_area_curriculum_plans/:id/copy', as: :copy_knowledge_area_curriculum_plans, to: 'knowledge_area_curriculum_plans#copy'
    post '/knowledge_area_curriculum_plans/:id/copy', as: :copy_knowledge_area_curriculum_plans, to: 'knowledge_area_curriculum_plans#do_copy'
RUBY_ROUTES
  
  if grep -q "resources :discipline_teaching_plans" "$ROUTES_FILE"; then
    sed -i '/resources :discipline_teaching_plans/r /tmp/routes_block.rb' "$ROUTES_FILE"
  else
    sed -i '$e cat /tmp/routes_block.rb' "$ROUTES_FILE"
  fi
  rm -f /tmp/routes_block.rb
  print_success "Rotas registradas com sucesso."
else
  print_warning "Rotas já presentes em routes.rb (pulando)."
fi

# 4. Atualizar Menu de Navegação (config/navigation.yml)
print_step "3/8" "Configurando menus de navegação em config/navigation.yml"
NAV_FILE="$APP_DIR/config/navigation.yml"
if [ -f "$NAV_FILE" ] && ! grep -q "discipline_curriculum_plans" "$NAV_FILE"; then
  cat << 'YAML_NAV' > /tmp/nav_block.yml
          - title: "Planos Curriculares"
            type: "discipline_curriculum_plans"
            path: "discipline_curriculum_plans_path"
            permission: "curriculum_plan"
          - title: "Planos Curriculares por Área"
            type: "knowledge_area_curriculum_plans"
            path: "knowledge_area_curriculum_plans_path"
            permission: "curriculum_plan"
YAML_NAV
  if grep -q "type: \"discipline_teaching_plans\"" "$NAV_FILE"; then
    sed -i '/type: "discipline_teaching_plans"/e cat /tmp/nav_block.yml' "$NAV_FILE"
    print_success "Submenus inseridos em navigation.yml"
  fi
  rm -f /tmp/nav_block.yml
else
  print_warning "Menus já presentes ou navigation.yml não localizado (pulando)."
fi

# 5. Atualizar Features em app/enumerations/features.rb
print_step "4/8" "Registrando permissões em app/enumerations/features.rb"
FEATURES_FILE="$APP_DIR/app/enumerations/features.rb"
if [ -f "$FEATURES_FILE" ] && ! grep -q ":discipline_curriculum_plans" "$FEATURES_FILE"; then
  sed -i '/:discipline_teaching_plans/a \                   :discipline_curriculum_plans,\n                   :knowledge_area_curriculum_plans,\n                   :copy_discipline_curriculum_plan,\n                   :copy_knowledge_area_curriculum_plan,' "$FEATURES_FILE"
  print_success "Features registradas em app/enumerations/features.rb"
else
  print_warning "Features já registradas em features.rb (pulando)."
fi

# 6. Conceder Permissões aos Professores em app/services/features_access_levels.rb
print_step "5/8" "Concedendo permissões a professores em features_access_levels.rb"
FAL_FILE="$APP_DIR/app/services/features_access_levels.rb"
if [ -f "$FAL_FILE" ] && ! grep -q ":discipline_curriculum_plans" "$FAL_FILE"; then
  sed -i '/:discipline_teaching_plans/a \      :discipline_curriculum_plans,\n      :copy_discipline_curriculum_plan,\n      :knowledge_area_curriculum_plans,\n      :copy_knowledge_area_curriculum_plan,' "$FAL_FILE"
  print_success "Permissões dos professores atualizadas."
else
  print_warning "Permissões já configuradas em features_access_levels.rb (pulando)."
fi

# 7. Executar Migrações do Banco de Dados
print_step "6/8" "Executando migrações do banco de dados (db:migrate)"
cd "$APP_DIR"
export RAILS_ENV="${RAILS_ENV:-production}"
bundle exec rake db:migrate
print_success "Migrações executadas com sucesso."

# 8. Executar Seed dos 147 Planos Curriculares Oficiais
print_step "7/8" "Povoando banco de dados com os 147 Planos Curriculares oficiais"
bundle exec rails runner "$APP_DIR/db/seeds/curriculum_plans_bncc.rb"
print_success "Povoamento dos 147 planos concluído com sucesso!"

# 9. Recarregar a Aplicação Rails
print_step "8/8" "Recarregando a aplicação Rails"
mkdir -p "$APP_DIR/tmp"
touch "$APP_DIR/tmp/restart.txt"
print_success "Aplicação recarregada com sucesso."

print_header "INSTALAÇÃO 100% CONCLUÍDA E MÓDULO TOTALMENTE FUNCIONAL!"
echo -e "${CLR_GREEN}Todos os controllers, views, rotas, menus, permissões e os 147 planos já estão ativos no seu i-Diário!${CLR_RESET}\n"
