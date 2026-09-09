# Arquitetura do projeto

O aplicativo segue uma organização simples por funcionalidade. Cada feature
contém suas telas, evitando que `lib/telas` vire um diretório único e difícil de
manter.

```text
lib/
  app.dart                     configuração visual do aplicativo
  routes.dart                  rotas de navegação
  services/                    API e serviços compartilhados
  widgets/                     componentes visuais reutilizáveis
  features/
    auth/                      login, cadastro e splash
    home/                      tela inicial
    profile/                   perfil do usuário
    questionnaire/             questionário
    assessment/                gráfico e relatórios
    history/                   histórico e armazenamento local
    settings/                  configurações
```

## Convenções para novas funcionalidades

Para uma feature nova, comece com um diretório e uma tela:

```text
features/nome_da_feature/
  nome_tela.dart
  nome_widget.dart             se for exclusivo da feature
```

- Componentes usados por duas ou mais features vão para `widgets`.
- API, armazenamento e serviços comuns vão para `services`.
- Rotas são declaradas apenas em `routes.dart`.
- Quando uma feature crescer muito, adicione subpastas `data`, `models` ou `widgets` somente nela.

## Próximas extrações recomendadas

1. Converter `historico_global.dart` em um repositório com modelo tipado.
2. Extrair o cálculo do questionário para `features/questionnaire/`.
3. Mover a geração de PDF para `services/`.
4. Criar um serviço de autenticação em `services/` quando a API for implementada.
