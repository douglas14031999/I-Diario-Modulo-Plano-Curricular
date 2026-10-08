# 📘 Módulo de Planos Curriculares da Rede (i-Diário)
> **Referencial Curricular Municipal Integrado à BNCC, EJA e AEE com Cópia em 1-Clique para os Professores**

Este repositório contém o código-fonte completo, migrações de banco de dados, visualizações, serviços e sementes (seeds) para implantar o módulo de **Planos Curriculares** no software de gestão escolar **i-Diário** (Ruby on Rails).

---

## 🌟 Principais Funcionalidades

1. **Gestão Curricular Centralizada (Secretaria de Educação):**
   * Cadastro, validação e manutenção da matriz curricular da rede por componente curricular ou por áreas do conhecimento.
   * Definição padronizada de metodologia, avaliação, referências, unidades temáticas, objetos de conhecimento e habilidades BNCC.
2. **Cópia em 1-Clique para os Professores:**
   * Professores podem navegar pelos Planos Curriculares oficiais e copiá-los diretamente para seus próprios **Planos de Ensino**, selecionando sua escola, turma e período.
3. **Povoamento Completo (147 Planos Oficiais):**
   * **Educação Infantil:** Creche, Pré-Escola e Unificada por Campos de Experiência.
   * **Ensino Fundamental Regular:** 1º ao 9º Ano com todas as 8/9 disciplinas.
   * **Ensino Fundamental Multisseriado:** Séries individuais (1º ao 5º Ano Multi) e série geral integrada (`MULTI`).
   * **EJA (1º Segmento - Anos Iniciais):** 9 planos com metodologia andragógica (alfabetização de adultos, matemática cidadã).
   * **EJA (2º Segmento - Anos Finais):** 9 planos com metodologia andragógica (mercado de trabalho, letramento crítico, finanças).
   * **AEE (Atendimento Educacional Especializado):** Planos por Área de Conhecimento e por Disciplina com os 9 eixos do PDI e 10 habilidades de acessibilidade.

---

## 📂 Estrutura de Arquivos

```
.
├── app/
│   ├── assets/javascripts/views/       # Scripts interativos de formulário
│   ├── controllers/                     # Controllers por Disciplina e por Área
│   ├── forms/                           # Formulários com validação e cópia
│   ├── helpers/                         # Helpers de visualização
│   ├── models/                          # Models ActiveRecord auditados
│   ├── policies/                        # Políticas de autorização Pundit
│   ├── reports/                         # Emissão de relatórios em PDF
│   ├── services/                        # Serviços de cópia segura com isolamento
│   └── views/                           # Telas SmartAdmin (Index, New, Edit, Show, Copy)
├── config/
│   ├── locales/                         # Traduções completas em Português (pt-BR)
│   └── patches/                         # Trechos de rotas, navegação e permissões
├── db/
│   ├── migrate/                         # 5 Migrações completas do PostgreSQL
│   └── seeds/
│       └── curriculum_plans_bncc.rb     # Seed idempotente dos 147 planos oficiais
├── bncc_oficial_consolidada.json        # Dataset oficial da BNCC
├── instalar.sh                          # Script de instalação automática em 1 comando
└── README.md
```

---

## 🚀 Instalação Automática

### Pré-requisitos
* Sistema **i-Diário** (versão 1.6 ou superior) em execução (Ruby 2.6+, Rails 5+, PostgreSQL).

### Passo a Passo

1. Clone ou copie este repositório para o servidor onde o i-Diário está instalado:
   ```bash
   git clone https://github.com/douglas14031999/I-Diario-Modulo-Plano-Curricular.git /tmp/modulo-planos
   ```

2. Execute o instalador automático informando o caminho do seu i-Diário:
   ```bash
   cd /tmp/modulo-planos
   chmod +x instalar.sh
   bash instalar.sh /caminho/para/i-diario
   ```
   *(Exemplo típico: `bash instalar.sh /root/i-diario` ou `bash instalar.sh /var/www/i-diario`)*

3. O script irá automaticamente:
   * ✅ Copiar todos os controllers, models, views, services, policies e reports.
   * ✅ Configurar as rotas em `config/routes.rb`.
   * ✅ Configurar os menus de navegação em `config/navigation.yml`.
   * ✅ Executar `rake db:migrate`.
   * ✅ Executar o seed de povoamento com os **147 planos curriculares**.

---

## ⚙️ Instalação Manual (Opcional)

Se preferir copiar manualmente:
1. Copie as pastas `app/`, `config/locales/` e `db/` para dentro do seu projeto i-Diário.
2. Copie `bncc_oficial_consolidada.json` para a raiz do i-Diário.
3. Adicione as rotas em `config/routes.rb`:
   ```ruby
   resources :discipline_curriculum_plans, concerns: :history
   get '/discipline_curriculum_plans/:id/copy', as: :copy_discipline_curriculum_plans, to: 'discipline_curriculum_plans#copy'
   post '/discipline_curriculum_plans/:id/copy', as: :copy_discipline_curriculum_plans, to: 'discipline_curriculum_plans#do_copy'

   resources :knowledge_area_curriculum_plans, concerns: :history
   get '/knowledge_area_curriculum_plans/:id/copy', as: :copy_knowledge_area_curriculum_plans, to: 'knowledge_area_curriculum_plans#copy'
   post '/knowledge_area_curriculum_plans/:id/copy', as: :copy_knowledge_area_curriculum_plans, to: 'knowledge_area_curriculum_plans#do_copy'
   ```
4. Execute as migrações e o seed:
   ```bash
   bundle exec rake db:migrate
   bundle exec rails runner db/seeds/curriculum_plans_bncc.rb
   ```

---

## 📄 Licença
Distribuído sob a licença do projeto i-Diário / GPL v2.
