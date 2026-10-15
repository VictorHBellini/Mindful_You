# Padronização de Estrutura de Pastas e Arquivos (Arquitetura e Rastreabilidade)
**Projeto:** Mindful You  
**Tipo de Documento:** Guia Técnico e Documentação de Padronização Estrutural (TCC)  
**Data:** 15 de Outubro de 2026  
**Status:** Mapeamento Arquitetural (Sem alteração física de arquivos no repositório)

---

## 1. Contexto e Motivação

O projeto **Mindful You** evoluiu a partir de uma estrutura inicial orientada a funcionalidades (`features/`), com apoio de `widgets/` e `services/`. Conforme novos requisitos foram adicionados (como o módulo de terapeuta, avaliações clínicas de rastreio, relatórios em PDF, autenticação híbrida SQLite/Firebase e criptografia de senhas), o repositório acumulou:

1. **Desvios de localização:** Telas inteiras implementadas dentro da pasta `widgets/`.
2. **Duplicidade e código morto:** Pastas inteiras clonadas que não são importadas pelas rotas ativas (ex.: `features/questionnaire/`).
3. **Inconsistência de nomenclatura:** Mistura de sufixos (`_tela.dart` vs `_page.dart`) e nomenclatura de componentes visuais tratados como telas.
4. **Sobrecarga da pasta `services/`:** Mistura de controladores de estado, utilitários criptográficos, geradores de ID e serviços de dados.
5. **Dificuldade de rastreio de caminhos:** Caminhos de importação longos e imprevisíveis entre features adjacentes.

Este documento tem como objetivo **documentar o estado atual (AS-IS)**, propor a **estrutura padronizada recomendada (TO-BE)** e fornecer uma **tabela de migração (De -> Para)** com regras claras de nomenclatura para facilitar manutenções futuras e enriquecer a documentação acadêmica do TCC.

---

## 2. Diagnóstico da Estrutura Atual (AS-IS)

### 2.1. Visão Geral da Árvore Atual em `lib/`

```text
lib/
├── app.dart                                # Configuração do MaterialApp e temas
├── firebase_options.dart                   # Configuração gerada do Firebase
├── main.dart                               # Entrypoint da aplicação
├── routes.dart                             # Declaração das rotas nomeadas
│
├── features/                               # Módulos por funcionalidade
│   ├── assessment/                         # Módulo de avaliações clínicas
│   │   ├── avaliacoes_tela.dart
│   │   ├── grafico_tela.dart               [ALERTA: Arquivo duplicado órfão]
│   │   ├── questionario_rastreio_tela.dart
│   │   └── registros_tela.dart
│   ├── auth/                               # Módulo de autenticação
│   │   ├── cadastro_tela.dart
│   │   ├── firebase_registros_teste_tela.dart [ALERTA: Tela de teste em produção]
│   │   ├── firebase_teste_tela.dart        [ALERTA: Tela de teste em produção]
│   │   ├── gerenciar_usuarios_tela.dart    [ALERTA: Funcionalidade de Admin dentro de Auth]
│   │   ├── login_tela.dart
│   │   └── splashscreen_tela.dart
│   ├── checkin/                            # Módulo de check-in diário
│   │   ├── grafico_tela.dart               # Gráfico de resultado do check-in
│   │   └── questionario_tela.dart          # Questionário do check-in ativo
│   ├── history/                            # Módulo de histórico
│   │   ├── firebase_historico_tela.dart
│   │   ├── historico_global.dart           [ALERTA: Lógica de negócio, cache e DB em features/]
│   │   └── historico_tela.dart
│   ├── home/                               # Módulo inicial
│   │   └── inicial_tela.dart
│   ├── legal/                              # Termos legais e privacidade
│   │   ├── politica_privacidade_tela.dart
│   │   └── termos_uso_tela.dart
│   ├── patient/                            # Módulo do paciente
│   │   └── consentimentos_tela.dart        [ALERTA: Pasta isolada com apenas 1 arquivo]
│   ├── profile/                            # Módulo de perfil do usuário
│   │   └── perfil_tela.dart
│   ├── questionnaire/                      # [ALERTA: Pasta 100% duplicada e órfã]
│   │   └── questionario_tela.dart
│   ├── settings/                           # Configurações do app
│   │   ├── configuracoes_tela.dart
│   │   └── vincular_firebase_demo_tela.dart
│   └── therapist/                          # Módulo do profissional/terapeuta
│       ├── avaliacoes_paciente_tela.dart
│       ├── historico_paciente_tela.dart
│       └── painel_terapeuta_tela.dart
│
├── services/                               # Serviços e utilitários
│   ├── admin_service.dart
│   ├── avaliacao_service.dart
│   ├── crypto_utils.dart                   [ALERTA: Utilitário puro alocado como serviço]
│   ├── database_service.dart
│   ├── firebase_conta_vinculo_service.dart
│   ├── firebase_perfil_service.dart
│   ├── firebase_registros_service.dart
│   ├── foto_perfil_service.dart
│   ├── operacao_id.dart                    [ALERTA: Função geradora de ID alocada como serviço]
│   ├── pdf_service.dart
│   ├── session_service.dart                [ALERTA: Gerenciamento de sessão/estado]
│   ├── theme_service.dart                  [ALERTA: Gerenciador de tema/estado]
│   └── vinculo_service.dart
│
└── widgets/                                # Componentes reutilizáveis
    ├── avatar_perfil.dart                  # Componente visual
    ├── dicas_page.dart                     [ALERTA: Tela completa em widgets/ e usando _page]
    ├── menu_lateral_tela.dart              [ALERTA: Drawer/Widget nomeado como _tela]
    ├── recuperar_senha_tela.dart           [ALERTA: Tela completa de auth em widgets/]
    ├── responsive_center.dart              # Utilitário de layout
    └── tela_legal_base.dart                # Template base para telas legais
```

---

### 2.2. Inconsistências Críticas Identificadas

1. **Telas completas armazenadas em `lib/widgets/`:**
   - [`lib/widgets/recuperar_senha_tela.dart`](file:///c:/dev/TCC/lib/widgets/recuperar_senha_tela.dart): Trata-se de uma tela de redefinição de credenciais que pertence conceitualmente a `features/auth/`.
   - [`lib/widgets/dicas_page.dart`](file:///c:/dev/TCC/lib/widgets/dicas_page.dart): É uma tela de navegação de nível superior (`/dicas`), com `Scaffold`, `AppBar` e conteúdo próprio. Deveria estar em `features/tips/` ou `features/wellness/`.

2. **Divergência de sufixos (`_page` vs `_tela`):**
   - O projeto adota `_tela.dart` em quase todos os arquivos (`login_tela.dart`, `inicial_tela.dart`), porém utiliza `dicas_page.dart`.
   - O Drawer lateral [`lib/widgets/menu_lateral_tela.dart`](file:///c:/dev/TCC/lib/widgets/menu_lateral_tela.dart) foi sufixado como `_tela`, embora não seja uma tela (`Scaffold`), mas sim um widget de gaveta (`Drawer`).

3. **Arquivos órfãos e pastas duplicadas (Redundância de Código):**
   - [`lib/features/questionnaire/questionario_tela.dart`](file:///c:/dev/TCC/lib/features/questionnaire/questionario_tela.dart) (66 KB) existe em duplicidade com [`lib/features/checkin/questionario_tela.dart`](file:///c:/dev/TCC/lib/features/checkin/questionario_tela.dart). O primeiro não possui nenhum import ativo no projeto.
   - [`lib/features/assessment/grafico_tela.dart`](file:///c:/dev/TCC/lib/features/assessment/grafico_tela.dart) (54 KB) é uma cópia não utilizada de [`lib/features/checkin/grafico_tela.dart`](file:///c:/dev/TCC/lib/features/checkin/grafico_tela.dart).

4. **Telas de depuração/teste dentro do fluxo de produção:**
   - `firebase_teste_tela.dart` e `firebase_registros_teste_tela.dart` estão soltas dentro de `features/auth/` e declaradas publicamente nas rotas de produção em [`routes.dart`](file:///c:/dev/TCC/lib/routes.dart#L24).

5. **Ausência da camada `core/` (Núcleo Compartilhado):**
   - Utilitários globais como `crypto_utils.dart` (hashing PBKDF2), `operacao_id.dart` (gerador UUID) e `responsive_center.dart` (layout) estão espalhados entre `services/` e `widgets/`.
   - Não existe um ponto central para constantes de design, temas e tipos fundamentais.

6. **Acoplamento em `historico_global.dart`:**
   - [`lib/features/history/historico_global.dart`](file:///c:/dev/TCC/lib/features/history/historico_global.dart) funciona simultaneamente como banco de dados intermediário, mapeador de tabelas, cache em memória e lógica de cálculo de sequências. Por estar na pasta de uma tela (`history/`), outras telas distantes (`inicial_tela`, `grafico_tela`, `login_tela`, `configuracoes_tela`) dependem de um arquivo interno de outra funcionalidade.

---

## 3. Estrutura Padronizada Recomendada (TO-BE)

A arquitetura recomendada para o **Mindful You** é o padrão **Feature-First + Core**, amplamente consagrado na comunidade Flutter por viabilizar alta manutenibilidade, separação clara de responsabilidades e rastreabilidade imediata de arquivos.

```text
lib/
├── app.dart                               # Configuração do MaterialApp
├── firebase_options.dart                  # Configurações do Firebase
├── main.dart                              # Inicialização global
│
├── core/                                  # Recursos transversais compartilhados
│   ├── constants/                         # Chaves, assets e constantes do app
│   │   ├── app_assets.dart                # Mapeamento centralizado de imagens/ícones
│   │   └── app_constants.dart             # Strings e limites do sistema
│   ├── database/                          # Acesso a banco de dados local
│   │   └── database_service.dart          # SQLite central
│   ├── routing/                           # Infraestrutura de navegação
│   │   └── app_routes.dart                # Definição e proteção de rotas
│   ├── theme/                             # Sistema de Design e Tema
│   │   ├── app_theme.dart                 # ThemeData claro e escuro
│   │   └── theme_controller.dart          # Gerenciamento de modo escuro/claro
│   ├── utils/                             # Utilitários puros
│   │   ├── crypto_utils.dart              # Hashing e criptografia
│   │   ├── operacao_id.dart               # Gerador de IDs de sessão
│   │   └── pdf_generator.dart             # Geração de relatórios
│   └── widgets/                           # Componentes visuais atômicos globais
│       ├── avatar_perfil.dart             # Avatar unificado
│       ├── custom_drawer.dart             # Menu lateral Drawer
│       ├── responsive_center.dart         # Contêiner responsivo
│       └── legal_screen_template.dart     # Template de telas legais
│
└── features/                              # Módulos organizados por domínio
    ├── admin/                             # Gestão e administração (apenas admin)
    │   └── screens/
    │       └── gerenciar_usuarios_screen.dart
    │
    ├── assessment/                        # Instrumentos e escalas de rastreio
    │   ├── services/
    │   │   └── avaliacao_service.dart
    │   └── screens/
    │       ├── avaliacoes_screen.dart
    │       └── questionario_rastreio_screen.dart
    │
    ├── auth/                              # Autenticação, Cadastro e Sessão
    │   ├── services/
    │   │   └── session_service.dart
    │   └── screens/
    │       ├── splash_screen.dart
    │       ├── login_screen.dart
    │       ├── cadastro_screen.dart
    │       └── recuperar_senha_screen.dart # [Movido de widgets/ para cá]
    │
    ├── checkin/                           # Check-in diário e autoavaliação
    │   ├── data/
    │   │   └── checkin_repository.dart    # [Substitui historico_global.dart]
    │   └── screens/
    │       ├── questionario_screen.dart
    │       ├── resultado_grafico_screen.dart
    │       └── relatorio_detalhes_screen.dart
    │
    ├── history/                           # Histórico de check-ins do paciente
    │   └── screens/
    │       └── historico_screen.dart
    │
    ├── home/                              # Tela principal do paciente
    │   └── screens/
    │       └── home_screen.dart
    │
    ├── legal/                             # Documentos normativos e LGPD
    │   └── screens/
    │       ├── politica_privacidade_screen.dart
    │       └── termos_uso_screen.dart
    │
    ├── patient/                           # Recursos do paciente (vínculos/consentimentos)
    │   └── screens/
    │       └── consentimentos_screen.dart
    │
    ├── profile/                           # Gestão de perfil e dados da conta
    │   ├── services/
    │   │   └── foto_perfil_service.dart
    │   └── screens/
    │       └── perfil_screen.dart
    │
    ├── settings/                          # Preferências e configurações do app
    │   └── screens/
    │       ├── configuracoes_screen.dart
    │       └── vincular_firebase_screen.dart
    │
    ├── therapist/                         # Painel e acompanhamento pelo terapeuta
    │   ├── services/
    │   │   └── vinculo_service.dart
    │   └── screens/
    │       ├── painel_terapeuta_screen.dart
    │       ├── historico_paciente_screen.dart
    │       └── avaliacoes_paciente_screen.dart
    │
    └── tips/                              # Dicas de saúde mental e respiração
        └── screens/
            └── dicas_screen.dart          # [Movido de widgets/ para cá]
```

---

## 4. Tabela de Mapeamento de Migração (DE -> PARA)

A tabela abaixo lista **cada arquivo atual do projeto**, sua localização recomendada no modelo padronizado e a justificativa arquitetural:

| Arquivo Atual | Localização Recomendada (TO-BE) | Justificativa da Padronização |
| :--- | :--- | :--- |
| `lib/app.dart` | `lib/app.dart` | Raiz de inicialização do MaterialApp. |
| `lib/routes.dart` | `lib/core/routing/app_routes.dart` | Centraliza infraestrutura de roteamento no `core`. |
| `lib/widgets/avatar_perfil.dart` | `lib/core/widgets/avatar_perfil.dart` | Componente reutilizado por Home, Histórico e Perfil. |
| `lib/widgets/menu_lateral_tela.dart` | `lib/core/widgets/custom_drawer.dart` | É um componente `Drawer`, não uma tela independente. |
| `lib/widgets/responsive_center.dart` | `lib/core/widgets/responsive_center.dart` | Componente estrutural compartilhado de responsividade. |
| `lib/widgets/tela_legal_base.dart` | `lib/core/widgets/legal_screen_template.dart` | Molde/template reutilizado por Termos e Privacidade. |
| `lib/widgets/dicas_page.dart` | `lib/features/tips/screens/dicas_screen.dart` | É uma tela de conteúdo; deve pertencer a uma feature própria e adotar o sufixo padrão. |
| `lib/widgets/recuperar_senha_tela.dart` | `lib/features/auth/screens/recuperar_senha_screen.dart` | Trata-se de fluxo de autenticação; deve residir em `auth/`. |
| `lib/features/auth/splashscreen_tela.dart` | `lib/features/auth/screens/splash_screen.dart` | Correção ortográfica do sufixo e separação por escopo. |
| `lib/features/auth/login_tela.dart` | `lib/features/auth/screens/login_screen.dart` | Padronização de nomenclatura. |
| `lib/features/auth/cadastro_tela.dart` | `lib/features/auth/screens/cadastro_screen.dart` | Padronização de nomenclatura. |
| `lib/features/auth/gerenciar_usuarios_tela.dart` | `lib/features/admin/screens/gerenciar_usuarios_screen.dart` | Isolação de perfil administrativo (segurança e organização). |
| `lib/features/auth/firebase_teste_tela.dart` | *Mover para pasta de testes / descontinuar* | Telas de laboratório/teste não devem residir em fluxos de produção. |
| `lib/features/auth/firebase_registros_teste_tela.dart` | *Mover para pasta de testes / descontinuar* | Telas de laboratório/teste não devem residir em fluxos de produção. |
| `lib/features/home/inicial_tela.dart` | `lib/features/home/screens/home_screen.dart` | Tela inicial do paciente. |
| `lib/features/checkin/questionario_tela.dart` | `lib/features/checkin/screens/questionario_screen.dart` | Tela ativa do questionário de check-in diário. |
| `lib/features/checkin/grafico_tela.dart` | `lib/features/checkin/screens/resultado_grafico_screen.dart` | Diferencia claramente o resultado do check-in de outros gráficos. |
| `lib/features/questionnaire/questionario_tela.dart` | *Exclusão recomendada (Arquivo Órfão)* | Cópia redundante sem uso nas rotas. |
| `lib/features/assessment/grafico_tela.dart` | *Exclusão recomendada (Arquivo Órfão)* | Cópia redundante sem uso nas rotas. |
| `lib/features/assessment/avaliacoes_tela.dart` | `lib/features/assessment/screens/avaliacoes_screen.dart` | Lista de escalas clínicas demonstrativas. |
| `lib/features/assessment/questionario_rastreio_tela.dart` | `lib/features/assessment/screens/questionario_rastreio_screen.dart` | Formulário de escalas de rastreio (GAD-7 / PHQ-9). |
| `lib/features/assessment/registros_tela.dart` | `lib/features/checkin/screens/relatorio_detalhes_screen.dart` | Relatório detalhado das respostas do check-in. |
| `lib/features/history/historico_tela.dart` | `lib/features/history/screens/historico_screen.dart` | Tela de histórico do paciente. |
| `lib/features/history/historico_global.dart` | `lib/features/checkin/data/checkin_repository.dart` | Converte lógica global em repositório estruturado de dados. |
| `lib/features/history/firebase_historico_tela.dart` | `lib/features/history/screens/firebase_historico_screen.dart` | Histórico remoto experimental. |
| `lib/features/profile/perfil_tela.dart` | `lib/features/profile/screens/perfil_screen.dart` | Tela de perfil do usuário. |
| `lib/features/settings/configuracoes_tela.dart` | `lib/features/settings/screens/configuracoes_screen.dart` | Configurações gerais e temas. |
| `lib/features/settings/vincular_firebase_demo_tela.dart` | `lib/features/settings/screens/vincular_firebase_screen.dart` | Tela de vinculação de conta. |
| `lib/features/patient/consentimentos_tela.dart` | `lib/features/patient/screens/consentimentos_screen.dart` | Gestão de autorizações do paciente. |
| `lib/features/therapist/painel_terapeuta_tela.dart` | `lib/features/therapist/screens/painel_terapeuta_screen.dart` | Dashboard do profissional. |
| `lib/features/therapist/historico_paciente_tela.dart` | `lib/features/therapist/screens/historico_paciente_screen.dart` | Consulta de prontuário autorizado. |
| `lib/features/therapist/avaliacoes_paciente_tela.dart` | `lib/features/therapist/screens/avaliacoes_paciente_screen.dart` | Consulta de rastreios clínicos autorizados. |
| `lib/features/legal/termos_uso_tela.dart` | `lib/features/legal/screens/termos_uso_screen.dart` | Termos de uso institucionais. |
| `lib/features/legal/politica_privacidade_tela.dart` | `lib/features/legal/screens/politica_privacidade_screen.dart` | Política de privacidade LGPD. |
| `lib/services/crypto_utils.dart` | `lib/core/utils/crypto_utils.dart` | Utilitário criptográfico transversal. |
| `lib/services/operacao_id.dart` | `lib/core/utils/operacao_id.dart` | Utilitário gerador de chaves de idempotência. |
| `lib/services/pdf_service.dart` | `lib/core/utils/pdf_generator.dart` | Utilitário gerador de documentos PDF. |
| `lib/services/theme_service.dart` | `lib/core/theme/theme_controller.dart` | Gerenciador reativo de estado de tema. |
| `lib/services/database_service.dart` | `lib/core/database/database_service.dart` | Conexão e esquemas de tabelas SQLite. |
| `lib/services/session_service.dart` | `lib/features/auth/services/session_service.dart` | Gerenciamento de ciclo de vida da sessão do usuário. |
| `lib/services/foto_perfil_service.dart` | `lib/features/profile/services/foto_perfil_service.dart` | Upload e armazenamento local de foto de perfil. |
| `lib/services/avaliacao_service.dart` | `lib/features/assessment/services/avaliacao_service.dart` | Serviços de pontuação e persistência de rastreio. |
| `lib/services/vinculo_service.dart` | `lib/features/therapist/services/vinculo_service.dart` | Lógica de solicitações e consentimentos paciente-terapeuta. |

---

## 5. Convenções de Nomenclatura e Regras de Rastreio

Para garantir a facilidade de manutenção futura e eliminar ambiguidades nos caminhos de importação (`imports`), foram estabelecidas as seguintes convenções:

### 5.1. Sufixos Obrigatórios de Arquivos
* **Telas (`Screens`):** Devem terminar obrigatoriamente com o sufixo `_screen.dart` (ex.: `login_screen.dart`, `historico_screen.dart`). Isso diferencia de imediato uma tela que ocupa o `Navigator` de um widget interno.
* **Componentes Parciais (`Widgets`):** Componentes locais de uma tela devem terminar em `_widget.dart` ou `_card.dart` e ficar numa subpasta `widgets/` dentro da respectiva feature.
* **Repositórios e Serviços de Dados:** Devem terminar com `_repository.dart` quando lidam com dados (banco/cache) ou `_service.dart` quando consomem APIs externas.
* **Modelos de Dados:** Devem terminar com `_model.dart` (ex.: `checkin_model.dart`, `usuario_model.dart`).

### 5.2. Padrão de Importações
* **Evitar imports relativos profundos com retrocessos longos** (ex.: `../../../../services/database_service.dart`).
* **Adotar sempre imports de pacote (`package imports`):**
  ```dart
  // Recomendado (rastreável e imune a movimentações de pasta locais):
  import 'package:mindful_you/core/database/database_service.dart';
  import 'package:mindful_you/features/checkin/screens/questionario_screen.dart';
  ```

---

## 6. Roteiro Passo a Passo para Futuras Migrações

Caso a equipe ou orientador do TCC decida aplicar as melhorias estruturais no código em etapas futuras, recomenda-se seguir o seguinte roteiro seguro:

1. **Fase 1 (Limpeza Segura):** Remover as pastas duplicadas sem referências (`lib/features/questionnaire/` e `lib/features/assessment/grafico_tela.dart`).
2. **Fase 2 (Criação do Core):** Criar `lib/core/` e mover utilitários puros (`crypto_utils.dart`, `operacao_id.dart`, `responsive_center.dart`).
3. **Fase 3 (Realocação de Telas em Widgets):** Mover `recuperar_senha_tela.dart` para `features/auth/` e `dicas_page.dart` para `features/tips/`.
4. **Fase 4 (Padronização de Nomenclatura):** Renomear gradativamente os sufixos para `_screen.dart` atualizando `routes.dart`.

---

> [!NOTE]
> Este documento de padronização serve como artefato de engenharia de software para o TCC, comprovando a aplicação de princípios como **Alta Coesão**, **Baixo Acoplamento**, **Separação de Preocupações (SoC)** e arquitetura **Clean Architecture / Feature-First**.
