# Diagnóstico do Frontend: Usabilidade, Responsividade e Arquitetura UI
**Projeto:** Mindful You  
**Tipo de Documento:** Relatório Técnico de Auditoria do Frontend (Documentação de TCC)  
**Data:** 15 de Outubro de 2026  
**Escopo:** Análise estática e dinâmica de Usabilidade, Responsividade, Acessibilidade e Design System (sem alteração de código operacional).

---

## 1. Visão Geral e Metodologia

Este documento sintetiza a varredura aprofundada realizada sobre a camada de frontend do aplicativo **Mindful You** (Flutter). A auditoria inspecionou telas, fluxos de navegação, formulários, componentes reutilizáveis, gerenciamento de temas e conformidade com diretrizes de usabilidade (Heurísticas de Nielsen, Material Design 3 e WCAG 2.1).

### Objetivos da Varredura
1. Identificar gargalos de **ergonomia cognitiva** e **usabilidade**.
2. Avaliar a **responsividade** em diferentes resoluções (smartphones compactos, orientação paisagem, tablets e desktop/web).
3. Mapear **inconsistências visuais**, falhas no **Tema Escuro** e **débitos técnicos estruturais**.
4. Servir como fundamentação teórica e prática para o capítulo de *Avaliação e Trabalhos Futuros* da monografia do TCC.

---

## 2. Diagnóstico de Usabilidade (UX / UI e Ergonomia Cognitiva)

### 2.1. Sobrecarga Cognitiva e Fadiga no Check-in Emocional
* **Arquivo:** [`lib/features/checkin/questionario_tela.dart`](file:///c:/dev/TCC/lib/features/checkin/questionario_tela.dart)
* **Situação Encontrada:** O formulário diário de autoavaliação exige a passagem linear por **22 telas obrigatórias consecutivas** (`_totalPaginas = 22`), intercalando seletores de emoções, múltiplos sliders (0 a 100), questões de frequência clínica e caixas de texto dissertativo (pensamentos automáticos, situações difíceis e momentos de leveza).
* **Problema:** Usuários em crise, sobrecarregados ou com ansiedade elevada enfrentam fadiga cognitiva extrema, gerando abandono imediato do registro. Não há mecanismo de salvamento de rascunho nem opção de preenchimento rápido.
* **Recomendação:**
  - Dividir em **Check-in Express** (humor + 1 slider + emoção principal em 3 passos) e **Reflexão Profunda** (opcional).
  - Permitir avanço sem resposta obrigatória em campos abertos e implementar persistência local de rascunho.

### 2.2. Antipatronagem na Visualização de Dados (Gráfico de Atenção)
* **Arquivo:** [`lib/features/checkin/grafico_tela.dart`](file:///c:/dev/TCC/lib/features/checkin/grafico_tela.dart)
* **Situação Encontrada:** A tela de resultado utiliza um gráfico de rosca (`PieChart`) com 4 fatias para exibir Cansaço, Sono, Ansiedade e Produtividade.
* **Problema:** Gráficos de pizza/rosca comunicam **partes de um mesmo todo (proporção de 100%)**. Como as 4 métricas são variáveis independentes (cada uma variando de 0 a 100), se todas estiverem altas (90%) ou todas baixas (10%), cada fatia continuará ocupando os mesmos 25% da pizza. O usuário não consegue discernir a gravidade absoluta do seu estado.
* **Recomendação:**
  - Substituir o gráfico circular por um **Gráfico de Radar (Spider Chart)** ou **Barras de Progresso Horizontais Segmentadas** com zonas de atenção coloridas (Verde / Amarelo / Terracota).

### 2.3. Aferição Quebrada (Broken Affordance) na Tela Inicial
* **Arquivo:** [`lib/features/home/inicial_tela.dart`](file:///c:/dev/TCC/lib/features/home/inicial_tela.dart)
* **Situação Encontrada:** O cartão de "Seu último check-in" exibe uma seta para a direita (`Icons.arrow_forward_ios_rounded`), sugerindo fortemente que é um botão clicável.
* **Problema:** O cartão é um `Container` estático sem `GestureDetector` ou `InkWell`. O usuário clica na seta e não obtém resposta, quebrando a heurística de *Correspondência com o Mundo Real* e *Previsibilidade*.
* **Recomendação:**
  - Adicionar interação de toque direcionando o usuário para o detalhamento daquele check-in (`/relatorio` ou tela de gráfico).

### 2.4. Inversão de Prioridade no Floating Action Button (FAB)
* **Arquivo:** [`lib/features/home/inicial_tela.dart`](file:///c:/dev/TCC/lib/features/home/inicial_tela.dart)
* **Situação Encontrada:** O botão flutuante principal da tela inicial possui o rótulo **"Consentimentos"** com ícone de escudo.
* **Problema:** O FAB é o elemento de maior peso visual e hierárquico de uma interface mobile. "Consentimentos" é uma tela de configuração jurídica/demonstrativa de acesso esporádico. A ação principal do app deveria ser registrar como o paciente está se sentindo ("+ Novo Check-in").
* **Recomendação:**
  - Deslocar "Consentimentos" para o menu lateral ou perfil, reservando o FAB para o fluxo principal de autocuidado.

### 2.5. Consentimento Sem Acesso aos Termos no Cadastro
* **Arquivo:** [`lib/features/auth/cadastro_tela.dart`](file:///c:/dev/TCC/lib/features/auth/cadastro_tela.dart)
* **Situação Encontrada:** O checkbox possui o texto estático `"Aceito os Termos de Uso e Política de Privacidade"`.
* **Problema:** Não há links clicáveis ou diálogos modais para visualizar o conteúdo antes da marcação. O usuário é induzido a aceitar termos que ele não pode consultar dentro da própria tela, em desacordo com as boas práticas da LGPD.
* **Recomendação:**
  - Adicionar `RichText` com `TextSpan` interativo que abre as rotas `/termos` e `/privacidade`.

### 2.6. Ciclo de Abertura da Splash Screen
* **Arquivo:** [`lib/features/auth/splashscreen_tela.dart`](file:///c:/dev/TCC/lib/features/auth/splashscreen_tela.dart)
* **Situação Encontrada:** Dispara um `Timer` de 4 segundos e redireciona sempre para `/login`.
* **Problema:** Tempo de espera excessivo e ausência de verificação da sessão ativa existente. Usuários já conectados no aparelho são forçados a passar novamente pela tela de login a cada inicialização.
* **Recomendação:**
  - Reduzir o tempo de exibição para 1.5s - 2s e verificar `SessionService.validar()`, enviando usuários autenticados diretamente para a tela inicial.

---

## 3. Diagnóstico de Responsividade e Adaptação Multiplataforma

### 3.1. Subutilização do Utilitário `ResponsiveCenter`
* **Arquivo:** [`lib/widgets/responsive_center.dart`](file:///c:/dev/TCC/lib/widgets/responsive_center.dart)
* **Situação Encontrada:** O projeto dispõe de um widget ideal para conter larguras excessivas (`ResponsiveCenter`), porém ele é usado apenas em [`dicas_page.dart`](file:///c:/dev/TCC/lib/widgets/dicas_page.dart).
* **Problema:** Em telas largas (tablets, iPads, navegadores web e desktops), formulários e botões em telas como Login, Cadastro, Inicial e Perfil esticam desproporcionalmente de uma extremidade à outra da janela (largura infinita).
* **Recomendação:**
  - Envolver o corpo das telas centrais com `ResponsiveCenter(maxWidth: 650)`.

### 3.2. Vulnerabilidade a Overflow em Modo Paisagem (Landscape)
* **Arquivos:**
  - [`lib/features/auth/login_tela.dart`](file:///c:/dev/TCC/lib/features/auth/login_tela.dart)
  - [`lib/features/auth/cadastro_tela.dart`](file:///c:/dev/TCC/lib/features/auth/cadastro_tela.dart)
* **Situação Encontrada:** Uso de `Stack` associando imagens de altura fixa (260px - 320px) com cartões inferiores de altura percentual rígida (`height: MediaQuery.of(context).size.height * 0.68`).
* **Problema:** Em aparelhos em orientação horizontal (altura útil de 380px a 450px) ou aparelhos ultracompactos, a soma da imagem com o container percentual ultrapassa os limites da tela física, gerando sobreposição indevida e corte de botões sem scroll externo.
* **Recomendação:**
  - Utilizar `CustomScrollView` com `SliverFillRemaining(hasScrollBody: false)` ou `LayoutBuilder` adaptativo.

### 3.3. Estouro por Teclado Virtual no Modal "Editar Perfil"
* **Arquivo:** [`lib/features/profile/perfil_tela.dart`](file:///c:/dev/TCC/lib/features/profile/perfil_tela.dart)
* **Situação Encontrada:** A função `mostrarEditarPerfil()` abre um `showModalBottomSheet` com 5 campos de texto em uma `Column(mainAxisSize: MainAxisSize.min)` não rolável com preenchimento inferior via `viewInsets.bottom`.
* **Problema:** Ao focar em qualquer campo de texto e abrir o teclado do sistema, a altura disponível é reduzida e o Flutter dispara o erro fatal `A RenderFlex overflowed by XXX pixels on the bottom`.
* **Recomendação:**
  - Envolver o formulário do BottomSheet em `Flexible(child: SingleChildScrollView(...))`.

---

## 4. Acessibilidade (WCAG 2.1 AA)

| Elemento / Tela | Problema Identificado | Norma WCAG Violada | Solução Recomendada |
| :--- | :--- | :--- | :--- |
| **Menu / Histórico** ([`historico_tela.dart`](file:///c:/dev/TCC/lib/features/history/historico_tela.dart)) | Ícones `#B5ACA4` em fundo `#F8F5F2` (contraste **2.06:1**) | WCAG 2.1 - 1.4.11 (Contraste Não Textual mínimo 3:1) | Escurecer para tom `#75665E` ou `#5E514A` garantindo contraste > 4.5:1. |
| **Emojis de Humor** ([`inicial_tela.dart`](file:///c:/dev/TCC/lib/features/home/inicial_tela.dart)) | `Image.asset` em `GestureDetector` sem texto alternativo | WCAG 2.1 - 1.1.1 (Conteúdo Não Textual) | Adicionar `Semantics(label: 'Sentimento Feliz', button: true)`. |
| **Escala de Fontes** (Múltiplas telas) | Containers com `height` estático (ex.: 58dp, 292dp) | WCAG 2.1 - 1.4.4 (Redimensionamento de Texto até 200%) | Utilizar preenchimentos internos dinâmicos (`padding`) em vez de alturas fixas. |

---

## 5. Consistência Visual e Arquitetura de Interface

### 5.1. Suporte Quebrado ao Tema Escuro (Dark Mode)
* **Situação Encontrada:** O aplicativo define um tema escuro completo em [`lib/app.dart`](file:///c:/dev/TCC/lib/app.dart) com persistência em [`ThemeService`](file:///c:/dev/TCC/lib/services/theme_service.dart).
* **Problema:** A quase totalidade das telas (`inicial_tela`, `login_tela`, `cadastro_tela`, `questionario_tela`, `perfil_tela`, `registros_tela`) codifica cores fixas (`Colors.white`, `Color(0xFFF8F5F2)`, `Color(0xFF40352F)`). Ao ativar o Tema Escuro nas configurações, a tela continua com fundo bege/branco brilhante.
* **Recomendação:** Substituir as constantes fixas por `Theme.of(context).colorScheme.surface`, `onSurface`, etc.

### 5.2. Dualidade Estética no App
* **Situação Encontrada:** O módulo do paciente possui visual acolhedor, tons terracota e ilustrações orgânicas. Em contraste, os módulos de avaliação (`avaliacoes_tela.dart`), consentimento (`consentimentos_tela.dart`) e painel do terapeuta (`painel_terapeuta_tela.dart`) utilizam botões padrão `FilledButton`/`OutlinedButton` e cards brutos do Material 3 sem estilização, gerando a sensação de "dois aplicativos diferentes".
* **Recomendação:** Padronizar componentes por meio de um Design System compartilhado.

### 5.3. Navegação com Acúmulo de Pilha
* **Arquivo:** [`lib/widgets/menu_lateral_tela.dart`](file:///c:/dev/TCC/lib/widgets/menu_lateral_tela.dart)
* **Situação Encontrada:** O método `navegarPara()` executa `Navigator.pushNamed()` com `Future.delayed(100ms)` ao clicar nos itens do Drawer.
* **Problema:** Alternar entre Home, Histórico e Dicas empilha instâncias repetidas na memória. O botão "Voltar" nativo do Android exige múltiplos cliques redundantes para fechar o aplicativo.
* **Recomendação:** Adicionar `pushReplacementNamed` ou adotar navegação por abas persistentes (`NavigationBar`).

### 5.4. Código Morto / Telas Duplicadas
* **Arquivos Identificados:**
  1. [`lib/features/questionnaire/questionario_tela.dart`](file:///c:/dev/TCC/lib/features/questionnaire/questionario_tela.dart) (66 KB): Arquivo órfão não referenciado (o app usa a pasta `checkin/`).
  2. [`lib/features/assessment/grafico_tela.dart`](file:///c:/dev/TCC/lib/features/assessment/grafico_tela.dart) (54 KB): Cópia não utilizada do gráfico de check-in.
* **Recomendação:** Limpeza dos arquivos órfãos para evitar ambiguidades em manutenções e documentação.

---

## 6. Matriz de Priorização para Trabalhos Futuros

| ID | Área | Oportunidade / Correção | Severidade | Esforço Estimado |
| :-: | :--- | :--- | :-: | :-: |
| **01** | Responsividade | Adicionar scroll no modal "Editar Perfil" (evitar RenderFlex overflow) | **Crítica** | Baixo |
| **02** | Usabilidade | Otimizar Splash Screen (validar sessão ativa e reduzir tempo) | **Alta** | Baixo |
| **03** | Usabilidade | Modularizar o questionário de 22 telas (Check-in Express vs Completo) | **Alta** | Médio |
| **04** | Visualização | Trocar gráfico de rosca por indicadores de barra ou radar | **Alta** | Médio |
| **05** | Design System | Vincular telas ao `Theme.of(context)` para funcionamento do Dark Mode | **Alta** | Médio |
| **06** | Responsividade | Aplicar `ResponsiveCenter` nas telas principais (Web e Tablets) | **Média** | Baixo |
| **07** | Acessibilidade | Elevar contraste de ícones para padrão WCAG AA (> 4.5:1) | **Média** | Baixo |
| **08** | Navegação | Corrigir empilhamento cíclico de rotas no menu lateral | **Média** | Médio |
| **09** | Usabilidade | Tornar clicável o cartão de "Último check-in" na Home | **Média** | Muito Baixo |
| **10** | Usabilidade | Substituir o FAB "Consentimentos" por ação de check-in na Home | **Média** | Muito Baixo |
| **11** | LGPD / UX | Inserir links navegáveis para Termos e Privacidade no Cadastro | **Média** | Muito Baixo |
| **12** | Higienização | Remover telas órfãs duplicadas (`features/questionnaire`) | **Baixa** | Muito Baixo |

---

## 7. Conclusão

O frontend do **Mindful You** estabelece uma base sólida em termos de proposta de valor e apelo estético para a área de saúde mental. Os ajustes documentados nesta varredura concentram-se na transição de um **protótipo funcional** para uma **experiência de usuário profissional e resiliente**, proporcionando fluidez em múltiplos dispositivos, inclusão por meio da acessibilidade e respeito aos limites cognitivos de usuários em acompanhamento emocional.
