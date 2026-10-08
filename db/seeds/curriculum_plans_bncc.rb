# frozen_string_literal: true
# ==============================================================================
# SEED: PLANOS CURRICULARES BNCC OFICIAIS
# (ENSINO FUNDAMENTAL, EDUCAÇÃO INFANTIL, EJA E AEE)
# i-Diário - Sistema de Gestão Escolar
# ==============================================================================

require 'json'
require 'set'

puts '=============================================================================='
puts '  INICIANDO POVOAMENTO DOS PLANOS CURRICULARES (BASE OFICIAL BNCC)'
puts '=============================================================================='

YEAR = 2026

# ------------------------------------------------------------------------------
# 1. Limpeza segura dos planos existentes de 2026
# ------------------------------------------------------------------------------
puts "
-> Limpando planos curriculares existentes do ano #{YEAR}..."
DisciplineCurriculumPlan.joins(:curriculum_plan).where(curriculum_plans: { year: YEAR }).destroy_all
KnowledgeAreaCurriculumPlan.joins(:curriculum_plan).where(curriculum_plans: { year: YEAR }).destroy_all
CurriculumPlan.where(year: YEAR).destroy_all
puts "-> Planos curriculares de #{YEAR} limpos com sucesso!"

# Limpar conteúdos e objetivos órfãos não associados a nenhum plano de ensino nem currículo
begin
  orphan_contents = Content.where.not(id: ContentsCurriculumPlan.select(:content_id))
                           .where.not(id: ContentsTeachingPlan.select(:content_id))
  orphan_count = orphan_contents.count
  orphan_contents.destroy_all if orphan_count > 0
  puts "-> Conteúdos órfãos removidos: #{orphan_count}"
rescue => e
  puts "-> Nota: Limpeza de conteúdos órfãos ignorada (#{e.message})"
end

begin
  orphan_objs = Objective.where.not(id: ObjectivesCurriculumPlan.select(:objective_id))
                         .where.not(id: ObjectivesTeachingPlan.select(:objective_id))
  orphan_obj_count = orphan_objs.count
  orphan_objs.destroy_all if orphan_obj_count > 0
  puts "-> Objetivos órfãos removidos: #{orphan_obj_count}"
rescue => e
  puts "-> Nota: Limpeza de objetivos órfãos ignorada (#{e.message})"
end

# ------------------------------------------------------------------------------
# 2. Localizar e Carregar Arquivo JSON Oficial da BNCC
# ------------------------------------------------------------------------------
json_path = nil
possible_json_paths = [
  Rails.root.join('bncc_oficial_consolidada.json'),
  Rails.root.join('..', 'bncc_oficial_consolidada.json'),
  '/root/i-diario/bncc_oficial_consolidada.json',
  Rails.root.join('bncc_v1.json'),
  '/root/i-diario/bncc_v1.json'
]

possible_json_paths.each do |p|
  if File.exist?(p)
    json_path = p
    break
  end
end

unless json_path
  puts "[ERRO] Arquivo JSON da BNCC não encontrado nos caminhos testados:"
  possible_json_paths.each { |p| puts "  - #{p}" }
  exit 1
end

puts "-> Carregando dados da BNCC de: #{json_path}..."
raw_data = File.read(json_path)
bncc_data = JSON.parse(raw_data)

# ------------------------------------------------------------------------------
# 3. Obter Usuário Responsável e Tipo de Período Escolar ANUAL
# ------------------------------------------------------------------------------
admin_user = User.where(login: 'admin').first || User.where(active: true).first || User.first
puts "-> Usuário autor dos planos: #{admin_user&.name} (#{admin_user&.login}, ID: #{admin_user&.id})"

school_term_type = SchoolTermType.where("description ILIKE ?", "%Anual%").first || SchoolTermType.first
puts "-> Tipo de Período Escolar: #{school_term_type&.description} (ID: #{school_term_type&.id})"

# ------------------------------------------------------------------------------
# 4. Diretrizes Pedagógicas Ricas e Estruturadas (Metodologia, Avaliação, Referências)
# ------------------------------------------------------------------------------

def build_methodology(comp, ano, is_multi = false)
  if is_multi
    return <<~HTML
      <p><strong>Diretrizes Metodológicas para Turmas Multisseriadas dos Anos Iniciais:</strong></p>
      <ul>
        <li><strong>Agrupamentos Produtivos e Níveis de Aprendizagem:</strong> Organização do espaço em grupos flexíveis por etapas de desenvolvimento e proficiência, promovendo a cooperação e a tutoria entre pares.</li>
        <li><strong>Temas Geradores e Projetos Integradores:</strong> Desenvolvimento de temas comuns que articulam os diferentes componentes, com diferenciação no nível de complexidade e nas atividades propostas para cada ano de escolaridade.</li>
        <li><strong>Estações de Aprendizagem e Cantos Pedagógicos:</strong> Circulação orientada por rotinas estruturadas (oficinas de leitura, cantos de matemática manipulável, pesquisa e produção criativa).</li>
        <li><strong>Mediação Diferenciada do Professor:</strong> Atendimento pedagógico individualizado e em pequenos grupos pelo docente, com foco na consolidação do processo de alfabetização e letramento pleno.</li>
      </ul>
    HTML
  end

  case comp.to_s.downcase
  when /matem/
    <<~HTML
      <p><strong>Abordagem Metodológica para o Ensino da Matemática (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Resolução de Problemas como Eixo Central:</strong> Situações-problema contextualizadas como ponto de partida para a introdução, desenvolvimento e consolidação de novos conceitos matemáticos.</li>
        <li><strong>Materiais Concretos e Manipuláveis:</strong> Utilização ativa de recursos físicos (material dourado, ábacos, tangram, malhas quadriculadas, sólidos geométricos) e digitais (softwares de geometria dinâmica, calculadoras e planilhas eletrônicas).</li>
        <li><strong>Investigação Matemática e Levantamento de Conjecturas:</strong> Estímulo à formulação de hipóteses, busca de regularidades e padrões, estimativa, argumentação lógica e validação coletiva de estratégias.</li>
        <li><strong>Letramento Matemático:</strong> Incentivo à verbalização e registro por escrito do raciocínio matemático, utilizando representações simbólicas, tabelas, diagramas e linguagem formal gradativa.</li>
        <li><strong>Conexões Interdisciplinares e Cotidiano:</strong> Aplicação dos conceitos em contextos reais (economia doméstica, consumo consciente, educação financeira, estatística cidadã, ciências e tecnologia).</li>
      </ul>
    HTML
  when /portug/
    <<~HTML
      <p><strong>Abordagem Metodológica para Língua Portuguesa (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Perspectiva Enunciativo-Discursiva:</strong> Trabalho com a linguagem centrada no texto e em situações reais de comunicação, considerando autoria, público-alvo, esfera social e intencionalidade.</li>
        <li><strong>Eixo Leitura e Escuta:</strong> Práticas frequentes de leitura compartilhada, guiada e autônoma de gêneros textuais variados; desenvolvimento de estratégias de decodificação, inferência, análise crítica e apreciação estética.</li>
        <li><strong>Eixo Produção de Textos:</strong> Condução do processo completo de escrita (planejamento, primeira versão, revisão orientada, reescrita e publicação/compartilhamento de produções).</li>
        <li><strong>Eixo Oralidade:</strong> Rodas de conversa, relatos orais, entrevistas, debates regrados e apresentações formais, desenvolvendo a escuta atenta e o respeito às variedades linguísticas.</li>
        <li><strong>Eixo Análise Linguística e Semiótica:</strong> Reflexão sistemática sobre o sistema de escrita alfabética, regularidades ortográficas, classes gramaticais, pontuação, coesão e recursos multissemióticos em uso funcional.</li>
      </ul>
    HTML
  when /ci[eê]nc/
    <<~HTML
      <p><strong>Abordagem Metodológica para Ciências da Natureza (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Ensino por Investigação:</strong> Problematização de fenômenos naturais e tecnológicos que desafiam os estudantes a formular hipóteses, planejar investigações, coletar dados e construir explicações baseadas em evidências.</li>
        <li><strong>Atividades Experimentais e Trabalho de Campo:</strong> Aulas práticas no laboratório, na horta escolar e no entorno comunitário, promovendo o contato direto com os objetos de estudo.</li>
        <li><strong>Uso de Modelos e Representações:</strong> Construção de maquetes, esquemas ilustrados, simulações digitais e tabelas comparativas para representação de processos e estruturas biológicas, químicas e geológicas.</li>
        <li><strong>Educação Ambiental e Saúde Coletiva:</strong> Projetos interdisciplinares voltados à conservação da biodiversidade, gestão de recursos hídricos, vacinação e hábitos de vida sustentáveis.</li>
        <li><strong>Letramento Científico:</strong> Formação de postura crítica, combate à desinformação e compreensão dos impactos éticos e sociais da ciência e tecnologia.</li>
      </ul>
    HTML
  when /hist/
    <<~HTML
      <p><strong>Abordagem Metodológica para História (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Trabalho com Fontes Históricas:</strong> Investigação e análise crítica de vestígios do passado (documentos textuais, fotografias, mapas históricos, objetos materiais, patrimônio edificado e depoimentos orais).</li>
        <li><strong>Construção do Pensamento Histórico:</strong> Desenvolvimento das noções de temporalidade, simultaneidade, permanências, rupturas, causas e consequências dos processos humanos no tempo.</li>
        <li><strong>Memória Coletiva e Identidade:</strong> Valorização da história local e das narrativas comunitárias articuladas à história regional, nacional e mundial.</li>
        <li><strong>Diversidade e Relações Étnico-Raciais:</strong> Cumprimento efetivo das Leis 10.639/03 e 11.645/08 com estudo aprofundado do protagonismo dos povos indígenas e da população negra na constituição da sociedade brasileira.</li>
        <li><strong>Cidadania e Direitos Humanos:</strong> Discussão de temas contemporâneos, regimes políticos, lutas sociais e valorização dos direitos humanos e do Estado Democrático de Direito.</li>
      </ul>
    HTML
  when /geog/
    <<~HTML
      <p><strong>Abordagem Metodológica para Geografia (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Desenvolvimento do Raciocínio Geográfico:</strong> Compreensão dos conceitos de espaço, lugar, paisagem, região e território a partir da relação sociedade-natureza.</li>
        <li><strong>Alfabetização e Letramento Cartográfico:</strong> Leitura, interpretação e confecção de mapas mentais, croquis, plantas baixas, maquetes de relevo, mapas temáticos e imagens de sensoriamento remoto (Google Earth e mapas interativos).</li>
        <li><strong>Estudos do Meio:</strong> Trabalho de campo no bairro e no município para observação in loco das dinâmicas socioespaciais, transformações urbanas, rurais e impactos ambientais.</li>
        <li><strong>Análise Escalar:</strong> Conexão sistemática entre a escala local, regional, nacional e global nas transformações econômicas, culturais e ambientais.</li>
        <li><strong>Geopolítica e Meio Ambiente:</strong> Análise crítica das questões agrárias, urbanização, desigualdades regionais, mudanças climáticas e sustentabilidade socioambiental.</li>
      </ul>
    HTML
  when /art/
    <<~HTML
      <p><strong>Abordagem Metodológica para Arte (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Articulação das Quatro Linguagens:</strong> Integração dinâmica entre Artes Visuais, Dança, Música e Teatro, além de manifestações das artes digitais e integradas.</li>
        <li><strong>Dimensões do Conhecimento Artístico:</strong> Vivência articulada entre Criação (fazer artístico), Leitura/Análise (compreensão formal e histórica), Fruição (sensibilidade estética) e Crítica (posicionamento contextualizado).</li>
        <li><strong>Experimentação de Materialidades:</strong> Uso diversificado de suportes, pigmentos, materiais recicláveis, instrumentos musicais convencionais e alternativos, corpo, voz e ferramentas digitais.</li>
        <li><strong>Patrimônio Cultural e Diversidade:</strong> Reconhecimento e valorização da cultura popular brasileira, manifestações artísticas locais, afro-brasileiras e indígenas.</li>
        <li><strong>Compartilhamento das Produções:</strong> Organização de saraus, exposições, mostras teatrais e festivais artísticos no âmbito escolar e comunitário.</li>
      </ul>
    HTML
  when /f[ií]sic/
    <<~HTML
      <p><strong>Abordagem Metodológica para Educação Física (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Cultura Corporal de Movimento:</strong> Vivência prática, apreciação e recriação dos saberes corporais organizados em jogos/brincadeiras, esportes, ginásticas, danças, lutas e práticas corporais de aventura.</li>
        <li><strong>Inclusão e Cooperação:</strong> Práticas pedagógicas que acolhem todos os estudantes, rompendo com a hipercompetitividade e adaptando regras para garantir a participação ativa e segura de todos.</li>
        <li><strong>Reflexão Crítica e Saberes sobre o Corpo:</strong> Problematização sobre saúde, qualidade de vida, lazer, padrões estéticos da mídia, doping e ética desportiva.</li>
        <li><strong>Protagonismo e Autonomia:</strong> Estímulo à autogestão de jogos, arbitragem compartilhada, criação de coreografias e adaptação de regras esportivas pelo coletivo de estudantes.</li>
      </ul>
    HTML
  when /ingl/
    <<~HTML
      <p><strong>Abordagem Metodológica para Língua Inglesa (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Língua Inglesa como Língua Franca:</strong> Foco no uso da língua como instrumento de comunicação global, interação intercultural e cidadania, sem imposição de padrões nativistas exclusivos.</li>
        <li><strong>Abordagem Comunicativa e Baseada em Tarefas:</strong> Propostas de aprendizagem contextualizadas (Task-Based Learning), com propósitos comunicativos reais (produção de podcasts, vlogs, folhetos informativos e debates).</li>
        <li><strong>Eixos Integrados:</strong> Prática articulada da Oralidade (compreensão e produção oral), Leitura (estratégias de skimming/scanning e inferência), Escrita (planejamento e produção) e Conhecimentos Linguísticos em contexto.</li>
        <li><strong>Letramento Digital e Gêneros Contemporâneos:</strong> Exploração de mídias autênticas (vídeos, letras de música, fóruns, redes sociais e notícias) como fontes pedagógicas dinâmicas.</li>
      </ul>
    HTML
  when /relig/
    <<~HTML
      <p><strong>Abordagem Metodológica para Ensino Religioso (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Perspectiva Não Confessional e Laica:</strong> Abordagem estritamente pluralista e respeitosa, pautada nas Ciências da Religião e nos Direitos Humanos, sem proselitismo religioso ou doutrinação.</li>
        <li><strong>Eixos Estruturantes da BNCC:</strong> Investigação sobre Identidades e Alteridades, Manifestações Religiosas e Crenças Religiosas e Filosofias de Vida.</li>
        <li><strong>Diálogo Inter-religioso e Tolerância:</strong> Promoção da cultura da paz, combate à intolerância religiosa e valorização da convivência fraterna entre diferentes crenças e convicções de não crença.</li>
        <li><strong>Pesquisa Documental e Narrativas Tradicionais:</strong> Estudo de textos sagrados, mitos de criação, símbolos, ritos funerários, memórias e ancestralidades (em especial de matrizes indígena e afro-brasileira).</li>
      </ul>
    HTML
  else
    <<~HTML
      <p><strong>Abordagem Metodológica Geral (#{ano}º Ano):</strong></p>
      <ul>
        <li><strong>Metodologias Ativas:</strong> Aprendizagem baseada em problemas, projetos colaborativos e sala de aula invertida, colocando o estudante no centro do processo formativo.</li>
        <li><strong>Práticas Contextualizadas:</strong> Conexão permanente entre os objetos de conhecimento e as vivências socioculturais da comunidade escolar.</li>
      </ul>
    HTML
  end
end

def build_methodology_infantil(nome_etapa)
  <<~HTML
    <p><strong>Proposta Pedagógica e Metodológica para a Educação Infantil (#{nome_etapa}):</strong></p>
    <ul>
      <li><strong>Eixos Estruturantes (Interações e Brincadeiras):</strong> As interações interpessoais e as brincadeiras constituem o cerne das experiências infantis, permitindo à criança construir sua identidade, expressar emoções, criar narrativas e compreender o mundo social e natural.</li>
      <li><strong>Garantia dos Seis Direitos de Aprendizagem e Desenvolvimento:</strong>
        <ul>
          <li><strong>Conviver:</strong> com outras crianças e adultos em pequenos e grandes grupos, valorizando a diversidade cultural e respeitando as diferenças;</li>
          <li><strong>Brincar:</strong> cotidianamente de diversas formas, em diferentes espaços e tempos, ampliando o repertório de jogos, cantigas e imaginação;</li>
          <li><strong>Participar:</strong> ativamente do planejamento da rotina, da escolha de brincadeiras e materiais, exercendo sua voz e autonomia;</li>
          <li><strong>Explorar:</strong> movimentos, gestos, sons, formas, texturas, cores, palavras, elementos da natureza e objetos do cotidiano;</li>
          <li><strong>Expressar:</strong> sentimentos, dúvidas, hipóteses, descobertas e criações por meio de múltiplas linguagens (corporal, plástica, musical, oral e escrita);</li>
          <li><strong>Conhecer-se:</strong> e construir uma imagem positiva de si, reconhecendo seus limites, potencialidades e valorizando suas raízes culturais.</li>
        </ul>
      </li>
      <li><strong>Organização dos Espaços e Tempos:</strong> Ambientes desafiadores e acolhedores organizados em cantos temáticos (faz de conta, leitura de histórias, artes plásticas, modelagem, blocos de construção, experiências sensoriais e exploração ao ar livre).</li>
      <li><strong>Rotina Pedagógica Flexível e Humanizada:</strong> Integração orgânica entre os momentos de cuidado e de educação (alimentação, higiene, repouso, acolhida, roda de conversa e atividades lúdicas dirigidas e livres).</li>
      <li><strong>Escuta Atenta e Documentação Pedagógica:</strong> Registro permanente da voz da criança, de suas falas curiosas e de seus modos singulares de se relacionar com o conhecimento.</li>
    </ul>
  HTML
end

def build_eja1_methodology(comp)
  case comp.to_s
  when 'Língua Portuguesa'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Língua Portuguesa (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Pedagogia da Palavra e Leitura de Mundo:</strong> Alfabetização e letramento fundamentados na experiência prévia do educando jovem e adulto, partindo de palavras geradoras e universos vocabulares vinculados à sua vivência cidadã, profissional e comunitária.</li>
        <li><strong>Gêneros Textuais Sociais e Práticos:</strong> Foco no uso real e funcional da língua escrita: leitura e preenchimento de formulários, contracheques, contas de consumo, bulas de remédio, notícias de jornal, mensagens digitais, placas de trânsito e contratos de trabalho.</li>
        <li><strong>Oralidade e Expressão Democrática:</strong> Roda de conversa e debates guiados que estimulam a expressão do pensamento crítico, argumentação, escuta empática e valorização da cultura popular oral.</li>
        <li><strong>Análise Linguística Funcional:</strong> Reflexão sobre o sistema de escrita alfabética, correspondência fonema-grafema e ortografia prática, evitando metodologias infantilizadas e respeitando o ritmo cognitivo do estudante trabalhador.</li>
      </ul>
    HTML
  when 'Matemática'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Matemática (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Matemática Cidadã e Financeira do Cotidiano:</strong> Valorização das estratégias de cálculo mental desenvolvidas empiricamente pelos alunos em seu cotidiano laboral e comercial.</li>
        <li><strong>Resolução de Problemas Reais:</strong> Trabalho prático com economia doméstica, orçamentos familiares, comparação de preços, compras a prazo vs. à vista, juros simples do comércio e leitura de extratos bancários.</li>
        <li><strong>Medidas e Grandezas:</strong> Estudo prático de sistemas de medidas (comprimento, massa, capacidade, tempo e áreas) aplicados a reformas residenciais, culinária, costura e agricultura.</li>
        <li><strong>Leitura de Dados e Estatística Básica:</strong> Interpretação de tabelas, gráficos de contas de luz/água e notícias estatísticas para consolidação da autonomia social.</li>
      </ul>
    HTML
  when 'Ciências'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Ciências da Natureza (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Saúde Coletiva e Autocuidado:</strong> Prevenção de doenças crônicas (hipertensão, diabetes), vacinação de adultos/idosos, saúde do trabalhador, primeiros socorros e combate à automedicação.</li>
        <li><strong>Sustentabilidade e Gestão de Recursos:</strong> Conscientização ambiental com foco na conservação de recursos hídricos locais, reciclagem, descarte correto de resíduos e alimentação saudável com alimentos da região.</li>
        <li><strong>Ciência, Tecnologia e Vida Diária:</strong> Compreensão dos impactos tecnológicos no trabalho e no lar, desmistificação de crenças e combate a fake news científicas.</li>
      </ul>
    HTML
  when 'História'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - História (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Memória, Trajetória e Identidade:</strong> Valorização da história oral e das histórias de vida dos estudantes como fontes históricas legítimas, conectando a trajetória pessoal às transformações do município e do país.</li>
        <li><strong>Mundo do Trabalho e Conquistas Sociais:</strong> Estudo das transformações nas relações de trabalho ao longo do tempo, direitos trabalhistas, cidadania e lutas por igualdade.</li>
        <li><strong>Diversidade Étnico-Racial e Cultural:</strong> Reconhecimento do papel das populações afrodescendentes e indígenas na formação social brasileira e combate a preconceitos no espaço comunitário.</li>
      </ul>
    HTML
  when 'Geografia'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Geografia (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Espaço Vivido e Relação Sociedade-Natureza:</strong> Análise crítica do bairro, das transformações urbanas e rurais e das condições de moradia, transporte público e infraestrutura.</li>
        <li><strong>Cartografia Social e Local:</strong> Leitura e produção de itinerários, mapas da comunidade, pontos de referência e compreensão da dinâmica espacial do município.</li>
        <li><strong>Migrações e Dinâmica Populacional:</strong> Reflexão sobre os movimentos migratórios regionais que frequentemente marcam as trajetórias dos educandos da EJA.</li>
      </ul>
    HTML
  when 'Arte'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Arte (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Cultura Popular e Valorização Artística:</strong> Resgate e valorização do artesanato regional, folclore, música popular, cordel e manifestações culturais trazidas pelos alunos.</li>
        <li><strong>Expressão e Sensibilidade:</strong> Oficinas práticas de pintura, modelagem e apreciação musical que promovem o bem-estar, a autoestima e a fruição estética.</li>
      </ul>
    HTML
  when 'Educação Física'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Educação Física (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Saúde, Ergonomia e Qualidade de Vida:</strong> Orientações sobre postura corporal adequada para a jornada de trabalho, prevenção de lesões por esforço repetitivo (LER/DORT) e alongamentos.</li>
        <li><strong>Lazer Ativo e Práticas Corporais:</strong> Caminhadas orientadas, ginástica preventiva, respiração e jogos cooperativos acessíveis a diferentes faixas etárias e condições físicas.</li>
      </ul>
    HTML
  when 'Ensino Religioso'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Ensino Religioso (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Ética, Respeito e Cidadania:</strong> Diálogo reflexivo sobre valores humanos fundamentais: solidariedade, empatia, respeito às diferenças e dignidade da pessoa humana.</li>
        <li><strong>Liberdade de Crença e Diálogo Inter-religioso:</strong> Promoção da convivência pacífica e combate à intolerância religiosa no cotidiano comunitário e escolar.</li>
      </ul>
    HTML
  when 'Língua Inglesa'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Língua Inglesa (EJA - Anos Iniciais):</strong></p>
      <ul>
        <li><strong>Inglês Instrumental e Cotidiano:</strong> Reconhecimento de vocabulário e expressões em inglês presentes na vida diária: termos tecnológicos (login, download, mouse, Wi-Fi), placas, embalagens comerciais e ferramentas de trabalho.</li>
        <li><strong>Comunicação Básica e Acolhedora:</strong> Atividades contextualizadas e funcionais sem foco em gramática prescritiva, promovendo a inclusão digital e cultural do educando.</li>
      </ul>
    HTML
  else
    "<p>Abordagem pedagógica integrada orientada aos princípios andragógicos da EJA.</p>"
  end
end

def build_eja2_methodology(comp)
  case comp.to_s
  when 'Língua Portuguesa'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Língua Portuguesa (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Letramento Crítico e Cidadania Digital:</strong> Desenvolvimento da capacidade de análise crítica de discursos midiáticos, redes sociais, notícias e identificação de desinformação (fake news).</li>
        <li><strong>Gêneros Argumentativos e da Esfera Pública:</strong> Produção e interpretação de textos opinativos, artigos de opinião, cartas de reclamação, abaixo-assinados, manifestos e debates regrados sobre temas comunitários.</li>
        <li><strong>Comunicação Profissional e Mundo do Trabalho:</strong> Redação de documentos técnicos e profissionais: currículos, relatórios, atas, e-mails formais e desenvolvimento de oratória para entrevistas de emprego e reuniões.</li>
        <li><strong>Literatura e Fruição Estética:</strong> Contato com autores da literatura brasileira e afro-brasileira que problematizam a realidade social, identidade e direitos humanos.</li>
      </ul>
    HTML
  when 'Matemática'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Matemática (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Educação Financeira Aplicada e Empreendedorismo:</strong> Cálculo de juros simples e compostos, análise crítica de taxas de cartão de crédito, empréstimos, financiamentos habitacionais e planejamento de pequenos negócios.</li>
        <li><strong>Álgebra e Funções em Contextos Reais:</strong> Uso de equações e funções para modelar variações de preços, consumo de combustíveis, produtividade e custos de produção.</li>
        <li><strong>Geometria Espacial e Prática:</strong> Cálculo de perímetros, áreas e volumes aplicados à construção civil, arquitetura popular, reformas e estocagem.</li>
        <li><strong>Estatística e Tomada de Decisão:</strong> Coleta, organização e análise crítica de dados amostrais, interpretação de gráficos e índices socioeconômicos (inflação, desemprego, IDH).</li>
      </ul>
    HTML
  when 'Ciências'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Ciências da Natureza (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Saúde Coletiva, Trabalho e Biotecnologia:</strong> Prevenção de doenças ocupacionais, ergonomia, saúde reprodutiva/sexual do adulto, imunização e avanços da biotecnologia/vacinas.</li>
        <li><strong>Transição Energética e Sustentabilidade:</strong> Matrizes energéticas (solar, eólica, fóssil), mudanças climáticas globais, pegada de carbono e preservação dos biomas brasileiros.</li>
        <li><strong>Química e Física do Cotidiano:</strong> Transformações químicas da matéria, reações na indústria e culinária, eletricidade básica residencial e segurança com instalações elétricas.</li>
      </ul>
    HTML
  when 'História'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - História (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Mundo do Trabalho e Lutas Sociais:</strong> As revoluções industriais, formação da classe trabalhadora, consolidação dos direitos trabalhistas (CLT) e os desafios da uberização e inteligência artificial no trabalho contemporâneo.</li>
        <li><strong>Brasil Contemporâneo e Democracia:</strong> Ditadura civil-militar, redemocratização, Constituição Cidadã de 1988 e o fortalecimento das instituições democráticas.</li>
        <li><strong>Relações Étnico-Raciais e Resistência:</strong> História da África e dos povos originários americanos, superação do racismo estrutural e valorização da diversidade cultural brasileira.</li>
      </ul>
    HTML
  when 'Geografia'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Geografia (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Geopolítica e Globalização:</strong> A divisão internacional do trabalho, blocos econômicos, impactos da globalização na economia local e tensões mundiais contemporâneas.</li>
        <li><strong>Dinâmica Urbana e Rural:</strong> Segregação socioespacial nas cidades, mobilidade urbana, reforma agrária, agronegócio e soberania alimentar.</li>
        <li><strong>Questão Ambiental e Recursos Estratégicos:</strong> Gestão de bacias hidrográficas, saneamento básico, transição ecológica e justiça climática.</li>
      </ul>
    HTML
  when 'Arte'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Arte (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Arte e Crítica Social:</strong> Manifestações artísticas engajadas (muralismo, grafite, teatro do oprimido, música popular brasileira e poesia marginal).</li>
        <li><strong>Culturas Tradicionais e Contemporâneas:</strong> Diálogo entre patrimônio cultural imaterial regional e expressões da arte contemporânea e digital.</li>
      </ul>
    HTML
  when 'Educação Física'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Educação Física (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Ergonomia, Ginástica Laboral e Saúde:</strong> Práticas corporais compensatórias para rotinas de trabalho pesado ou sedentário, combate ao estresse e promoção do bem-estar.</li>
        <li><strong>Cultura Corporal e Lazer:</strong> O esporte e a atividade física como direito social de lazer e convivência comunitária na vida adulta.</li>
      </ul>
    HTML
  when 'Ensino Religioso'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Ensino Religioso (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Ética, Direitos Humanos e Diversidade Religiosa:</strong> Filosofia moral, alteridade, promoção da paz e diálogo inter-religioso no contexto comunitário.</li>
        <li><strong>Mística, Sentido da Vida e Transcendência:</strong> Reflexão sobre os anseios humanos por justiça, dignidade e respeito mútuo.</li>
      </ul>
    HTML
  when 'Língua Inglesa'
    <<~HTML
      <p><strong>Proposta Metodológica Andragógica - Língua Inglesa (EJA - 2º Segmento / Anos Finais):</strong></p>
      <ul>
        <li><strong>Língua Inglesa Instrumental e Mercado de Trabalho:</strong> Interpretação de manuais técnicos, termos corporativos, comércio exterior e vocabulário digital profissional.</li>
        <li><strong>Interculturalidade e Conexão Global:</strong> A língua inglesa como língua franca de comunicação internacional e ferramenta de acesso ao conhecimento global.</li>
      </ul>
    HTML
  else
    "<p>Abordagem pedagógica integrada orientada aos princípios andragógicos da EJA - Anos Finais.</p>"
  end
end

def build_eja_evaluation
  <<~HTML
    <p><strong>Avaliação Emancipatória e Formativa na EJA:</strong></p>
    <ul>
      <li><strong>Caráter Diagnóstico e Contínuo:</strong> A avaliação ocorre ao longo de todo o percurso pedagógico, compreendida como instrumento de orientação da aprendizagem e não como mecanismo seletivo ou punitivo.</li>
      <li><strong>Valorização do Progresso Individual:</strong> Consideração do ponto de partida de cada estudante trabalhador, respeitando seu ritmo, suas limitações de tempo e seu avanço contínuo.</li>
      <li><strong>Instrumentos Diversificados:</strong> Produção textual gradativa, relatos orais em roda de conversa, tarefas práticas contextualizadas, resolução de desafios do cotidiano e autoavaliação participativa.</li>
      <li><strong>Feedback Dialógico e Encorajador:</strong> Devolutivas frequentes e construtivas que fortalecem a autoconfiança e a persistência escolar do jovem e adulto.</li>
    </ul>
  HTML
end

def build_eja_references
  <<~HTML
    <p><strong>Referências Normativas e Teórico-Metodológicas da EJA:</strong></p>
    <ul>
      <li>BRASIL. Ministério da Educação. <em>Base Nacional Comum Curricular (BNCC): Educação é a Base</em>. Brasília: MEC/SEB, 2018.</li>
      <li>BRASIL. Conselho Nacional de Educação. <em>Diretrizes Curriculares Nacionais para a Educação de Jovens e Adultos</em> (Parecer CNE/CEB nº 11/2000 e Resolução CNE/CEB nº 1/2000).</li>
      <li>FREIRE, Paulo. <em>Pedagogia da Autonomia: Saberes necessários à prática educativa</em>. São Paulo: Paz e Terra, 1996.</li>
      <li>KNOWLES, Malcolm S. <em>Andragogia: A prática da educação de adultos</em>. Rio de Janeiro: LTC, 2009.</li>
      <li>Proposta Pedagógica e Diretrizes Curriculares da Rede Municipal de Ensino.</li>
    </ul>
  HTML
end

def build_aee_methodology
  <<~HTML
    <p><strong>Proposta Metodológica do Atendimento Educacional Especializado (AEE - Sala de Recursos Multifuncionais):</strong></p>
    <ul>
      <li><strong>Natureza Complementar e Suplementar:</strong> O AEE tem caráter não substitutivo à escolarização comum, estruturado para identificar, elaborar e organizar recursos pedagógicos e de acessibilidade que eliminem as barreiras para a plena participação dos alunos com deficiência, TGD/TEA e altas habilidades/superdotação.</li>
      <li><strong>Elaboração e Execução do PDI (Plano de Desenvolvimento Individual):</strong> Planejamento personalizado centrado no perfil de potencialidades, necessidades específicas e metas pedagógicas individuais de cada estudante.</li>
      <li><strong>Mediação e Ensino Estruturado:</strong> Utilização de pistas visuais, rotinas organizadas, materiais táteis, concretos e multisensoriais, além de tecnologias assistivas adaptadas.</li>
      <li><strong>Trabalho Colaborativo e Articulação com a Sala Comum:</strong> Parceria contínua entre o professor de AEE, os professores regentes das disciplinas/áreas e a coordenação pedagógica, orientando adaptações e flexibilizações curriculares necessárias.</li>
      <li><strong>Orientação à Família e Comunidade Escolar:</strong> Envolvimento ativo dos responsáveis para o fortalecimento da autonomia e continuidade dos estímulos nos ambientes doméstico e social.</li>
    </ul>
  HTML
end

def build_aee_evaluation
  <<~HTML
    <p><strong>Avaliação no Âmbito do Atendimento Educacional Especializado:</strong></p>
    <ul>
      <li><strong>Avaliação Formativa e Processual (Sem Fins Classificatórios):</strong> O AEE não atribui notas numéricas ou conceitos classificatórios de promoção/retenção escolar.</li>
      <li><strong>Registro de Evolução no Estudo de Caso e PDI:</strong> Acompanhamento contínuo por meio de relatórios circunstanciados descritivos, portfólios de atividades, registros fotográficos e pareceres pedagógicos semestrais.</li>
      <li><strong>Critérios de Avaliação Centrados no Aluno:</strong> Medição do avanço do estudante em relação a si mesmo (conquista de autonomia, interação social, uso eficaz dos recursos de tecnologia assistiva e superação de barreiras comunicacionais e cognitivas).</li>
    </ul>
  HTML
end

def build_aee_references
  <<~HTML
    <p><strong>Referências Normativas e Teórico-Metodológicas da Educação Especial Inclusiva:</strong></p>
    <ul>
      <li>BRASIL. Ministério da Educação. <em>Política Nacional de Educação Especial na Perspectiva da Educação Inclusiva</em>. Brasília: MEC/SECADI, 2008.</li>
      <li>BRASIL. Presidência da República. <em>Decreto nº 7.611, de 17 de novembro de 2011</em> (Dispõe sobre a Educação Especial e o Atendimento Educacional Especializado).</li>
      <li>BRASIL. Conselho Nacional de Educação. <em>Resolução CNE/CEB nº 4/2009</em> (Diretrizes Operacionais para o Atendimento Educacional Especializado na Educação Básica).</li>
      <li>BRASIL. Lei nº 13.146, de 6 de julho de 2015. <em>Lei Brasileira de Inclusão da Pessoa com Deficiência (Estatuto da Pessoa com Deficiência)</em>.</li>
      <li>MANTOAN, Maria Teresa Eglér. <em>Inclusão Escolar: O que é? Por quê? Como fazer?</em> São Paulo: Moderna, 2015.</li>
      <li>Diretrizes da Secretaria Municipal de Educação para o Atendimento Educacional Especializado e Salas de Recursos Multifuncionais.</li>
    </ul>
  HTML
end

def build_evaluation(is_infantil = false)
  if is_infantil
    <<~HTML
      <p><strong>Diretrizes de Avaliação na Educação Infantil:</strong></p>
      <ul>
        <li><strong>Caráter Formativo e Acompanhamento Processual:</strong> Avaliação realizada sem objetivo de promoção, classificação ou retenção, conforme estabelecido no Artigo 31 da Lei de Diretrizes e Bases da Educação Nacional (LDB nº 9.394/96).</li>
        <li><strong>Instrumentos e Registros Documentais:</strong>
          <ul>
            <li>Relatórios descritivos semestrais do percurso individual de desenvolvimento da criança;</li>
            <li>Portfólios e diários de bordo com produções artísticas, escritas espontâneas e hipóteses infantis;</li>
            <li>Registros fotográficos e filmagens comentadas de momentos de interação e brincadeira;</li>
            <li>Pautas de observação sensível sobre autonomia, comunicação, esquema corporal e socialização.</li>
          </ul>
        </li>
        <li><strong>Comunicação com as Famílias:</strong> Diálogo permanente com pais e responsáveis para partilha de conquistas, singularidades e necessidades de cada criança.</li>
      </ul>
    HTML
  else
    <<~HTML
      <p><strong>Diretrizes de Avaliação Formativa e Processual (Ensino Fundamental):</strong></p>
      <ul>
        <li><strong>Avaliação Formativa e Contínua:</strong> Concebida como bússola pedagógica orientadora da aprendizagem e da prática docente, identificando avanços, potencialidades e necessidades individuais dos estudantes.</li>
        <li><strong>Dimensões da Avaliação:</strong>
          <ul>
            <li><strong>Diagnóstica:</strong> Mapeamento dos conhecimentos prévios e sondagens periódicas no início de cada unidade/bimestre;</li>
            <li><strong>Processual/Formativa:</strong> Acompanhamento contínuo das atividades diárias, participação e evolução das hipóteses de aprendizagem;</li>
            <li><strong>Somativa/Integradora:</strong> Síntese bimestral/anual das competências e habilidades consolidadas.</li>
          </ul>
        </li>
        <li><strong>Instrumentos Diversificados:</strong>
          <ul>
            <li>Observação estruturada com rubricas claras de critérios avaliativos;</li>
            <li>Produções textuais, relatórios de pesquisa e cadernos pedagógicos;</li>
            <li>Apresentações orais, seminários e projetos interdisciplinares individuais e coletivos;</li>
            <li>Avaliações escritas dissertativas e objetivas com foco na resolução de problemas;</li>
            <li>Autoavaliação discente, promovendo a metacognição e a corresponsabilidade no processo educativo.</li>
          </ul>
        </li>
        <li><strong>Intervenção e Recuperação Contínua:</strong> Planejamento imediato de estratégias pedagógicas diferenciadas para estudantes que apresentarem defasagens, assegurando a progressão das aprendizagens sem espera pelo final do período letivo.</li>
      </ul>
    HTML
  end
end

def build_references(is_infantil = false)
  if is_infantil
    <<~HTML
      <p><strong>Referências Normativas e Bibliográficas:</strong></p>
      <ul>
        <li>BRASIL. Ministério da Educação. <em>Base Nacional Comum Curricular: Educação Infantil</em>. Brasília: MEC/Secretaria de Educação Básica, 2018.</li>
        <li>BRASIL. Ministério da Educação. <em>Diretrizes Curriculares Nacionais para a Educação Infantil</em> (Resolução CNE/CEB nº 5/2009). Brasília: MEC, 2009.</li>
        <li>BRASIL. <em>Lei de Diretrizes e Bases da Educação Nacional</em> (Lei nº 9.394/1996 e alterações subsequentes).</li>
        <li>SECRETARIA MUNICIPAL DE EDUCAÇÃO. <em>Referencial Curricular Municipal e Proposta Pedagógica da Educação Infantil</em>.</li>
        <li>HORN, Maria da Graça Souza. <em>Sabores, cores, sons, aromas: a organização dos espaços na educação infantil</em>. Porto Alegre: Artmed, 2004.</li>
        <li>OLIVEIRA, Zilma de Moraes Ramos de. <em>Educação Infantil: fundamentos e métodos</em>. São Paulo: Cortez, 2012.</li>
      </ul>
    HTML
  else
    <<~HTML
      <p><strong>Referências Normativas e Bibliográficas:</strong></p>
      <ul>
        <li>BRASIL. Ministério da Educação. <em>Base Nacional Comum Curricular: Ensino Fundamental</em>. Brasília: MEC/Secretaria de Educação Básica, 2018.</li>
        <li>BRASIL. Ministério da Educação. <em>Diretrizes Curriculares Nacionais Gerais para a Educação Básica</em> (Resolução CNE/CEB nº 4/2010). Brasília: MEC, 2010.</li>
        <li>BRASIL. <em>Lei de Diretrizes e Bases da Educação Nacional</em> (Lei nº 9.394/1996 e alterações subsequentes).</li>
        <li>BRASIL. Leis nº 10.639/2003 e 11.645/2008 (História e Cultura Afro-Brasileira e Indígena no currículo escolar).</li>
        <li>SECRETARIA MUNICIPAL DE EDUCAÇÃO. <em>Diretrizes Curriculares Municipais e Proposta Pedagógica da Rede</em>.</li>
        <li>PERRENOUD, Philippe. <em>Avaliação: da excelência à regulação das aprendizagens – entre duas lógicas</em>. Porto Alegre: Artmed, 1999.</li>
        <li>ZABALA, Antoni. <em>A prática educativa: como ensinar</em>. Porto Alegre: Artmed, 1998.</li>
      </ul>
    HTML
  end
end

# ------------------------------------------------------------------------------
# 5. Garantia e Mapeamento de Séries (Grades)
# ------------------------------------------------------------------------------
# Garantir existência das séries do Curso Multi (1º ao 5º ano e MULTI)
course_multi = Course.where('description ILIKE ?', '%multi%').first
if course_multi
  Grade.find_or_create_by!(course_id: course_multi.id, description: '1º ANO') { |g| g.api_code = '24' }
  Grade.find_or_create_by!(course_id: course_multi.id, description: '2º ANO') { |g| g.api_code = '25' }
  Grade.find_or_create_by!(course_id: course_multi.id, description: '3º ANO') { |g| g.api_code = '26' }
  Grade.find_or_create_by!(course_id: course_multi.id, description: '4º ANO') { |g| g.api_code = '27' }
  Grade.find_or_create_by!(course_id: course_multi.id, description: '5º ANO') { |g| g.api_code = '28' }
  Grade.find_or_create_by!(course_id: course_multi.id, description: 'MULTI') { |g| g.api_code = '4' }
end

# Garantir existência da série ANOS FINAIS no Curso EJA 2º Segmento
course_eja2 = Course.where('description ILIKE ?', '%2º Segmento%').first || Course.find_by(id: 4)
if course_eja2
  Grade.find_or_create_by!(course_id: course_eja2.id, description: 'ANOS FINAIS') { |g| g.api_code = '29' }
end

# Garantir Área de Conhecimento e Disciplina de AEE
ka_aee = KnowledgeArea.find_or_create_by!(description: 'Atendimento Educacional Especializado (AEE)') do |k|
  k.api_code = '10'
  k.sequence = 8
end
disc_aee = Discipline.find_or_create_by!(description: 'Atendimento Educacional Especializado (AEE)') do |d|
  d.api_code = '25'
  d.knowledge_area = ka_aee
end

grade_map_ef = {
  1 => Grade.where("description ILIKE ?", "1%ANO%").pluck(:id),
  2 => Grade.where("description ILIKE ?", "2%ANO%").pluck(:id),
  3 => Grade.where("description ILIKE ?", "3%ANO%").pluck(:id),
  4 => Grade.where("description ILIKE ?", "4%ANO%").pluck(:id),
  5 => Grade.where("description ILIKE ?", "5%ANO%").pluck(:id),
  6 => Grade.where("description ILIKE ?", "6%ANO%").pluck(:id),
  7 => Grade.where("description ILIKE ?", "7%ANO%").pluck(:id),
  8 => Grade.where("description ILIKE ?", "8%ANO%").pluck(:id),
  9 => Grade.where("description ILIKE ?", "9%ANO%").pluck(:id)
}

multi_grade_ids = Grade.where("description = 'MULTI' OR description ILIKE '%MULTI%'").where.not(id: grade_map_ef.values.flatten).pluck(:id)

# ------------------------------------------------------------------------------
# 6. Mapeamento de Componentes Curriculares para Disciplinas do Banco
# ------------------------------------------------------------------------------
discipline_map = {
  'Arte'              => Discipline.where("description ILIKE ?", "%Artes%").first,
  'Ciências'          => Discipline.where("description ILIKE ?", "%Ciências%").first,
  'Educação Física'   => Discipline.where("description ILIKE ?", "%Educação física%").first,
  'Ensino Religioso'  => Discipline.where("description ILIKE ?", "%Ensino religioso%").first,
  'Geografia'         => Discipline.where("description ILIKE ?", "%Geografia%").first,
  'História'          => Discipline.where("description ILIKE ?", "%História%").first,
  'Língua Inglesa'    => Discipline.where("description ILIKE ?", "%Inglês%").first,
  'Língua Portuguesa' => Discipline.where("description ILIKE ?", "%portuguesa%").first,
  'Matemática'        => Discipline.where("description ILIKE ?", "%Matemática%").first
}

def normalize_comp_key(comp_name)
  case comp_name.to_s.downcase.strip
  when /art/ then 'Arte'
  when /ci[eê]nc/ then 'Ciências'
  when /f[ií]sic/ then 'Educação Física'
  when /relig/ then 'Ensino Religioso'
  when /geog/ then 'Geografia'
  when /hist/ then 'História'
  when /ingl/ then 'Língua Inglesa'
  when /port/ then 'Língua Portuguesa'
  when /mat/ then 'Matemática'
  else comp_name
  end
end

# ------------------------------------------------------------------------------
# 7. Processar e Gerar Planos Curriculares do Ensino Fundamental (Regular e Multi)
# ------------------------------------------------------------------------------
puts "
------------------------------------------------------------------------------"
puts "  GERANDO PLANOS CURRICULARES DO ENSINO FUNDAMENTAL (1º AO 9º ANO)"
puts "------------------------------------------------------------------------------"

ef_habs = bncc_data['ensino_fundamental'] || bncc_data['habilidades']&.select { |h| h['etapa'] == 'ensino_fundamental' } || []
puts "-> Total de habilidades no dataset: #{ef_habs.size}"

ef_grupos = Hash.new { |h, k| h[k] = { habilidades: [], objetos: Set.new, unidades: Set.new } }

ef_habs.each do |h|
  comp_norm = normalize_comp_key(h['componente'])
  next unless discipline_map.key?(comp_norm)

  anos = (h['anos'] || []).map(&:to_i)
  anos.each do |ano_num|
    next unless ano_num.between?(1, 9)
    next if comp_norm == 'Língua Inglesa' && ano_num < 6

    key = [ano_num, comp_norm]
    ef_grupos[key][:habilidades] << h
    (h['objetos_conhecimento'] || []).each do |obj|
      obj_str = obj.to_s.strip
      ef_grupos[key][:objetos].add(obj_str) if obj_str.present?
    end
    ut_str = h['unidade_tematica'].to_s.strip
    ef_grupos[key][:unidades].add(ut_str) if ut_str.present?
  end
end

created_plans_ef = 0

ActiveRecord::Base.transaction do
  ef_grupos.keys.sort.each do |(ano, comp_norm)|
    dados = ef_grupos[[ano, comp_norm]]
    disc = discipline_map[comp_norm]
    next unless disc

    target_grade_ids = grade_map_ef[ano] || []
    next if target_grade_ids.empty?

    contents = []
    if dados[:objetos].any?
      dados[:objetos].to_a.sort.each do |obj_desc|
        contents << Content.find_or_create_by!(description: obj_desc)
      end
    else
      fallback_desc = "#{disc.description} - Competências e Habilidades (#{ano}º Ano)"
      contents << Content.find_or_create_by!(description: fallback_desc)
    end

    objectives = []
    dados[:habilidades].each do |hab|
      codigo = hab['codigo']
      descricao = hab['descricao']
      obj_full = "(#{codigo}) #{descricao}"
      objectives << Objective.find_or_create_by!(description: obj_full)
    end

    unidades_text = dados[:unidades].to_a.sort.join('; ')
    unidades_text = 'Base Nacional Comum Curricular' if unidades_text.blank?

    target_grade_ids.each do |gid|
      grade = Grade.find_by(id: gid)
      next unless grade

      cp = CurriculumPlan.new(
        year: YEAR,
        grade: grade,
        school_term_type: school_term_type,
        school_term_type_step: nil,
        unity_name: 'Toda a Rede Municipal',
        methodology: build_methodology(comp_norm, ano, false),
        evaluation: build_evaluation(false),
        references: build_references(false),
        created_by_user: admin_user
      )
      cp.contents = contents.uniq
      cp.objectives = objectives.uniq
      cp.save!

      dcp = DisciplineCurriculumPlan.new(
        curriculum_plan: cp,
        discipline: disc,
        thematic_unit: unidades_text
      )
      dcp.not_validate_columns = true
      dcp.current_user = admin_user
      dcp.save!
      created_plans_ef += 1
    end
    print '.'
  end
end

puts "
-> Ensino Fundamental concluído com sucesso: #{created_plans_ef} planos gerados!"

# ------------------------------------------------------------------------------
# 8. Processar e Gerar Planos Curriculares para Série Agrupadora MULTI
# ------------------------------------------------------------------------------
if multi_grade_ids.any?
  puts "
-> Gerando planos para série geral MULTI (Grade IDs: #{multi_grade_ids.join(', ')})..."
  multi_grade_ids.each do |mgid|
    grade = Grade.find_by(id: mgid)
    next unless grade

    discipline_map.each do |comp_norm, disc|
      next unless disc
      next if comp_norm == 'Língua Inglesa'

      multi_contents = []
      multi_objectives = []
      multi_unidades = Set.new

      (1..5).each do |a|
        dados = ef_grupos[[a, comp_norm]]
        next unless dados

        dados[:objetos].each do |obj_desc|
          multi_contents << Content.find_or_create_by!(description: obj_desc)
        end

        dados[:habilidades].each do |hab|
          obj_full = "(#{hab['codigo']}) #{hab['descricao']}"
          multi_objectives << Objective.find_or_create_by!(description: obj_full)
        end

        dados[:unidades].each { |u| multi_unidades.add(u) }
      end

      next if multi_contents.empty?

      cp = CurriculumPlan.new(
        year: YEAR,
        grade: grade,
        school_term_type: school_term_type,
        school_term_type_step: nil,
        unity_name: 'Toda a Rede Municipal',
        methodology: build_methodology(comp_norm, nil, true),
        evaluation: build_evaluation(false),
        references: build_references(false),
        created_by_user: admin_user
      )
      cp.contents = multi_contents.uniq
      cp.objectives = multi_objectives.uniq
      cp.save!

      dcp = DisciplineCurriculumPlan.new(
        curriculum_plan: cp,
        discipline: disc,
        thematic_unit: multi_unidades.to_a.sort.join('; ')
      )
      dcp.not_validate_columns = true
      dcp.current_user = admin_user
      dcp.save!
      created_plans_ef += 1
      print '*'
    end
  end
  puts "
-> Série geral MULTI concluída!"
end

# ------------------------------------------------------------------------------
# 9. Processar e Gerar Planos Curriculares da Educação Infantil
# ------------------------------------------------------------------------------
puts "
------------------------------------------------------------------------------"
puts "  GERANDO PLANOS CURRICULARES DA EDUCAÇÃO INFANTIL (POR ÁREA DE CONHECIMENTO)"
puts "------------------------------------------------------------------------------"

ka_infantil = KnowledgeArea.where("description ILIKE ?", "%Infantil%").first || KnowledgeArea.find_by(id: 7)
grade_creche = Grade.where("description ILIKE ?", "%CRECHE%").first || Grade.find_by(id: 8)
grade_pre_escola = Grade.where("description ILIKE ?", "%PRÉ-ESCOLA%").first || Grade.find_by(id: 9)
grade_unificada = Grade.where("description ILIKE ?", "%UNIFICADA%").first || Grade.find_by(id: 10)

ei_data = bncc_data['educacao_infantil'] || []

CAMPOS_EXPERIENCIA_BNCC = [
  "O eu, o outro e o nós",
  "Corpo, gestos e movimentos",
  "Traços, sons, cores e formas",
  "Escuta, fala, pensamento e imaginação",
  "Espaços, tempos, quantidades, relações e transformações"
].freeze

ei_contents = CAMPOS_EXPERIENCIA_BNCC.map do |campo|
  Content.find_or_create_by!(description: "Campo de Experiência: #{campo}")
end

ei_grade_targets = [
  { grupo_filtro: ['ei-grupo-01', 'ei-grupo-02', '01', '02'], grade: grade_creche, nome: 'Creche (0 a 3 anos)' },
  { grupo_filtro: ['ei-grupo-03', '03'], grade: grade_pre_escola, nome: 'Pré-Escola (4 e 5 anos)' },
  { grupo_filtro: ['ei-grupo-01', 'ei-grupo-02', 'ei-grupo-03', '01', '02', '03'], grade: grade_unificada, nome: 'Unificada (0 a 5 anos)' }
]

created_plans_ei = 0

ActiveRecord::Base.transaction do
  ei_grade_targets.each do |config|
    grade = config[:grade]
    next unless grade

    objs_subset = ei_data.select do |o|
      grupo = o['grupo_etario'].to_s
      config[:grupo_filtro].any? { |f| grupo.include?(f) }
    end

    objectives = []
    objs_subset.each do |o|
      codigo = o['codigo']
      descricao = o['descricao']
      obj_full = "(#{codigo}) #{descricao}"
      objectives << Objective.find_or_create_by!(description: obj_full)
    end

    if objectives.empty?
      ei_data.each do |o|
        obj_full = "(#{o['codigo']}) #{o['descricao']}"
        objectives << Objective.find_or_create_by!(description: obj_full)
      end
    end

    cp = CurriculumPlan.new(
      year: YEAR,
      grade: grade,
      school_term_type: school_term_type,
      school_term_type_step: nil,
      unity_name: 'Toda a Rede Municipal',
      methodology: build_methodology_infantil(config[:nome]),
      evaluation: build_evaluation(true),
      references: build_references(true),
      created_by_user: admin_user
    )
    cp.contents = ei_contents.uniq
    cp.objectives = objectives.uniq
    cp.save!

    plan_ka = KnowledgeAreaCurriculumPlan.new(
      curriculum_plan: cp,
      experience_fields: CAMPOS_EXPERIENCIA_BNCC.join('; ')
    )
    plan_ka.knowledge_areas << ka_infantil if ka_infantil
    plan_ka.save!
    created_plans_ei += 1
    print '.'
  end
end

puts "
-> Educação Infantil concluída com sucesso: #{created_plans_ei} planos gerados!"

# ------------------------------------------------------------------------------
# 10. Processar e Gerar Planos Curriculares da EJA (1º Segmento - Anos Iniciais)
# ------------------------------------------------------------------------------
puts "
------------------------------------------------------------------------------"
puts "  GERANDO PLANOS DA EJA - 1º SEGMENTO (ANOS INICIAIS)"
puts "------------------------------------------------------------------------------"

grade_eja1 = Grade.find_by(id: 1) || Grade.where("description ILIKE ?", "%ANOS INICIAIS%").first
created_plans_eja1 = 0

if grade_eja1
  multi_plans = CurriculumPlan.where(grade_id: 6, year: YEAR)

  discipline_map.each do |comp_nome, disc|
    next unless disc

    source_cp = multi_plans.detect { |p| p.discipline_curriculum_plan&.discipline_id == disc.id }
    if source_cp.nil?
      source_cp = CurriculumPlan.joins(:discipline_curriculum_plan)
                                .where(year: YEAR, discipline_curriculum_plans: { discipline_id: disc.id })
                                .first
    end

    contents = source_cp ? source_cp.contents : []
    objectives = source_cp ? source_cp.objectives : []

    cp = CurriculumPlan.new(
      year: YEAR,
      grade: grade_eja1,
      school_term_type: school_term_type,
      school_term_type_step: nil,
      unity_name: 'Toda a Rede Municipal - EJA',
      methodology: build_eja1_methodology(comp_nome),
      evaluation: build_eja_evaluation,
      references: build_eja_references,
      created_by_user: admin_user
    )
    cp.contents = contents.uniq
    cp.objectives = objectives.uniq
    cp.save!

    thematic_unit = source_cp&.discipline_curriculum_plan&.thematic_unit || 'Base Nacional Comum Curricular / EJA'
    dcp = DisciplineCurriculumPlan.new(
      curriculum_plan: cp,
      discipline: disc,
      thematic_unit: thematic_unit
    )
    dcp.not_validate_columns = true
    dcp.current_user = admin_user
    dcp.save!
    created_plans_eja1 += 1
    print '+'
  end
  puts "
-> EJA 1º Segmento concluída com sucesso: #{created_plans_eja1} planos gerados!"
end

# ------------------------------------------------------------------------------
# 11. Processar e Gerar Planos Curriculares da EJA (2º Segmento - Anos Finais)
# ------------------------------------------------------------------------------
puts "
------------------------------------------------------------------------------"
puts "  GERANDO PLANOS DA EJA - 2º SEGMENTO (ANOS FINAIS)"
puts "------------------------------------------------------------------------------"

grade_eja2 = Grade.where(description: 'ANOS FINAIS').first
created_plans_eja2 = 0

if grade_eja2
  finais_grade_ids = [2, 3, 4, 5]
  plans_finais_regular = CurriculumPlan.where(grade_id: finais_grade_ids, year: YEAR)

  discipline_map.each do |comp_nome, disc|
    next unless disc

    disc_plans = plans_finais_regular.select { |p| p.discipline_curriculum_plan&.discipline_id == disc.id }
    combined_contents = disc_plans.map(&:contents).flatten.compact.uniq
    combined_objectives = disc_plans.map(&:objectives).flatten.compact.uniq

    cp = CurriculumPlan.new(
      year: YEAR,
      grade: grade_eja2,
      school_term_type: school_term_type,
      school_term_type_step: nil,
      unity_name: 'Toda a Rede Municipal - EJA Anos Finais',
      methodology: build_eja2_methodology(comp_nome),
      evaluation: build_eja_evaluation,
      references: build_eja_references,
      created_by_user: admin_user
    )
    cp.contents = combined_contents
    cp.objectives = combined_objectives
    cp.save!

    dcp = DisciplineCurriculumPlan.new(
      curriculum_plan: cp,
      discipline: disc,
      thematic_unit: 'Base Nacional Comum Curricular / EJA - Anos Finais'
    )
    dcp.not_validate_columns = true
    dcp.current_user = admin_user
    dcp.save!
    created_plans_eja2 += 1
    print '+'
  end
  puts "
-> EJA 2º Segmento concluída com sucesso: #{created_plans_eja2} planos gerados!"
end

# ------------------------------------------------------------------------------
# 12. Processar e Gerar Planos Curriculares do AEE (Educação Especial)
# ------------------------------------------------------------------------------
puts "
------------------------------------------------------------------------------"
puts "  GERANDO PLANOS CURRICULARES DO AEE (ÁREA DE CONHECIMENTO E DISCIPLINA)"
puts "------------------------------------------------------------------------------"

grade_aee = Grade.find_by(id: 7) || Grade.where("description ILIKE ?", "%AEE%").first
created_plans_aee = 0

if grade_aee
  eixos_aee = [
    'Tecnologia Assistiva e Recursos de Acessibilidade (softwares leitores, teclados adaptados, ponteiras, recursos de baixa e alta tecnologia)',
    'Comunicação Aumentativa e Alternativa - CAA (pranchas de comunicação, PECS, vocalizadores e símbolos gráficos para apoio à linguagem)',
    'Desenvolvimento das Funções Executivas e Cognitivas (atenção sustentada, memória de trabalho, flexibilidade cognitiva e controle inibitório)',
    'Estimulação Psicomotora e Sensorial (esquema corporal, coordenação motora fina/ampla, integração sensorial e lateralidade)',
    'Autonomia e Atividades de Vida Diária - AVD (higiene, alimentação, organização de materiais escolares, locomoção e autocuidado)',
    'Língua Brasileira de Sinais (Libras como L1 para surdos e L2 para comunidade escolar)',
    'Sistema Braille, Soroban e Orientação e Mobilidade para estudantes com deficiência visual',
    'Habilidades Socioemocionais, Interação Social e Manejo Comportamental (convivência inclusiva e autorregulação emocional)',
    'Enriquecimento Curricular e Aprofundamento para Altas Habilidades / Superdotação (projetos de pesquisa, criatividade e liderança)'
  ]

  objetivos_aee = [
    '(AEE01) Identificar, produzir e disponibilizar recursos de acessibilidade e tecnologia assistiva que eliminem barreiras pedagógicas.',
    '(AEE02) Desenvolver a comunicação funcional por meio de recursos de Comunicação Aumentativa e Alternativa (CAA) para interação nos espaços escolares.',
    '(AEE03) Estimular habilidades cognitivas básicas e superiores (atenção, percepção, memória, abstração e resolução de problemas práticos).',
    '(AEE04) Aprimorar o desenvolvimento psicomotor, a orientação espacial e temporal e a coordenação motora para o acesso às tarefas escolares.',
    '(AEE05) Fomentar a autonomia, independência e autodeterminação do educando nas atividades escolares e de vida diária.',
    '(AEE06) Promover o ensino e o uso da Libras e de recursos visuais para estudantes surdos, favorecendo o bilinguismo na escola.',
    '(AEE07) Ensinar o Sistema Braille (leitura e escrita pontográfica), o uso do Soroban e técnicas de Orientação e Mobilidade.',
    '(AEE08) Fortalecer habilidades de convivência, regulação emocional, flexibilidade comportamental e interação com os pares na sala comum.',
    '(AEE09) Articular ações pedagógicas colaborativas com os professores da classe comum para a flexibilização e adequação curricular.',
    '(AEE10) Proporcionar atividades de enriquecimento curricular exploratório e temático para alunos com altas habilidades/superdotação.'
  ]

  aee_contents = eixos_aee.map { |c| Content.find_or_create_by!(description: c) }
  aee_objs = objetivos_aee.map { |o| Objective.find_or_create_by!(description: o) }

  # Plano por Área de Conhecimento
  cp_aee_ka = CurriculumPlan.new(
    year: YEAR,
    grade: grade_aee,
    school_term_type: school_term_type,
    school_term_type_step: nil,
    unity_name: 'Toda a Rede Municipal - AEE',
    methodology: build_aee_methodology,
    evaluation: build_aee_evaluation,
    references: build_aee_references,
    created_by_user: admin_user
  )
  cp_aee_ka.contents = aee_contents
  cp_aee_ka.objectives = aee_objs
  cp_aee_ka.save!

  plan_ka_aee = KnowledgeAreaCurriculumPlan.new(
    curriculum_plan: cp_aee_ka,
    experience_fields: 'Tecnologia Assistiva; Comunicação Alternativa; Desenvolvimento Cognitivo; Autonomia e Vida Diária; Linguagens Específicas'
  )
  plan_ka_aee.knowledge_areas << ka_aee
  plan_ka_aee.save!
  created_plans_aee += 1

  # Plano por Disciplina
  cp_aee_disc = CurriculumPlan.new(
    year: YEAR,
    grade: grade_aee,
    school_term_type: school_term_type,
    school_term_type_step: nil,
    unity_name: 'Toda a Rede Municipal - AEE',
    methodology: build_aee_methodology,
    evaluation: build_aee_evaluation,
    references: build_aee_references,
    created_by_user: admin_user
  )
  cp_aee_disc.contents = aee_contents
  cp_aee_disc.objectives = aee_objs
  cp_aee_disc.save!

  dcp_aee = DisciplineCurriculumPlan.new(
    curriculum_plan: cp_aee_disc,
    discipline: disc_aee,
    thematic_unit: 'Educação Especial Inclusiva / Atendimento Educacional Especializado (AEE)'
  )
  dcp_aee.not_validate_columns = true
  dcp_aee.current_user = admin_user
  dcp_aee.save!
  created_plans_aee += 1

  puts "
-> AEE concluído com sucesso: #{created_plans_aee} planos gerados!"
end

# ------------------------------------------------------------------------------
# 13. Resumo Geral Oficial
# ------------------------------------------------------------------------------
puts "
=============================================================================="
puts "  POVOAMENTO DOS PLANOS CONCLUÍDO COM 100% DE SUCESSO!"
puts "=============================================================================="
total_disc = DisciplineCurriculumPlan.joins(:curriculum_plan).where(curriculum_plans: { year: YEAR }).count
total_ka = KnowledgeAreaCurriculumPlan.joins(:curriculum_plan).where(curriculum_plans: { year: YEAR }).count
puts "Resumo Oficial da Rede:"
puts "  • Planos por Disciplina (EF, Multi, EJA, AEE): #{total_disc} planos"
puts "  • Planos por Área de Conhecimento (EI e AEE):  #{total_ka} planos"
puts "  • Total Geral de Planos Curriculares Ativos:   #{total_disc + total_ka} planos"
puts "  • Total de Conteúdos no Sistema:               #{Content.count}"
puts "  • Total de Objetivos no Sistema:               #{Objective.count}"
puts "=============================================================================="
