# Money Control

[English](README.md) | [Português](README.pt-BR.md)

O Money Control é uma aplicação Ruby on Rails para organização de finanças pessoais. Ele reúne contas, transações, categorias, carteiras de investimentos, ativos de mercado, movimentações de investimentos e recebíveis em uma aplicação autenticada.

## Funcionalidades atuais

- Gerenciar contas financeiras e saldos.
- Criar, editar, filtrar e importar transações a partir de arquivos CSV.
- A organização por categorias está em análise e teste; sua continuidade será avaliada antes de ser tratada como uma funcionalidade estável.
- Gerenciar carteiras de investimentos e posições.
- Acompanhar movimentações de investimentos e recebíveis.
- Importar recebíveis de investimentos a partir de arquivos XLSX com revisão manual e verificação de duplicidades.
- Consultar desempenho de carteiras, valores de mercado, análises de recebíveis e relatórios fiscais.
- Ocultar valores financeiros sensíveis com o controle global de privacidade.
- Gerar backups PostgreSQL com acesso restrito a administradores.

Para conhecer as responsabilidades dos domínios, consulte [o resumo da estrutura do código](docs/code-overview.md).

## Requisitos

- Ruby 3.2.6 (consulte `.ruby-version`).
- PostgreSQL, com PostgreSQL 16 utilizado pelo ambiente de CI.
- Bundler.
- Node.js não é necessário para o fluxo normal de desenvolvimento; o JavaScript usa import maps do Rails.
- `pg_dump` e `pg_restore` são necessários para operações de backup e restauração do banco.

## Configuração local

1. Clone o repositório e entre no diretório do projeto.
2. Copie o template de ambiente:

   ```bash
   cp .env.example .env
   ```

3. Adicione os valores de integrações locais ao `.env` quando necessário. Nunca faça commit do `.env` ou de credenciais reais.
4. Execute o script de configuração idempotente:

   ```bash
   bin/setup
   ```

O `bin/setup` instala as dependências, prepara o banco, limpa logs e arquivos temporários locais e reinicia o servidor Rails.

## Execução local

Para executar o Rails e o watcher do Tailwind juntos:

```bash
bin/dev
```

Para executar apenas o servidor Rails:

```bash
bin/rails server
```

Por padrão, a aplicação fica disponível em [http://localhost:3000](http://localhost:3000).

Para gerar o CSS uma vez:

```bash
bin/rails tailwindcss:build
```

## Variáveis de ambiente

O arquivo versionado [.env.example](.env.example) documenta as variáveis locais suportadas:

- `BRAPI_API_TOKEN`: token opcional para consultas de dados de mercado.
- `BRAPI_MAX_SYMBOLS_PER_REQUEST`: quantidade máxima de símbolos por chamada ao provedor.

Os valores de conexão com o banco devem ser fornecidos pela configuração do Rails ou por `DATABASE_URL` no ambiente. Não coloque credenciais de produção em arquivos versionados.

## Testes e CI

Execute a suíte completa com:

```bash
bundle exec rspec
```

O fluxo de CI também compila o Tailwind e carrega o schema de testes antes de executar o RSpec. Consulte [o workflow de CI](.github/workflows/ci.yml) para conhecer o pipeline exato.

Comandos úteis para escopos específicos:

```bash
bundle exec rspec spec/requests
bundle exec rspec spec/services
git diff --check
```

## Estrutura do projeto

- `app/models`: persistência e associações dos domínios.
- `app/controllers`: tratamento de requisições autenticadas e fluxos com escopo por usuário.
- `app/services`: regras de negócio, análises, importações, relatórios e limites de integrações externas.
- `app/policies`: regras de autorização para recursos protegidos.
- `app/views`: views ERB do Rails e navegação compartilhada.
- `app/components`: componentes de interface reutilizáveis com ViewComponent.
- `lib/market_data`: contratos e implementações dos provedores de mercado.
- `lib/tasks`: tarefas Rails personalizadas, incluindo comandos operacionais do banco.
- `spec`: testes de modelos, requisições, políticas, serviços, helpers e componentes.
- `docs`: governança, arquitetura e documentação operacional.

## Segurança e tratamento de dados

- A autenticação é aplicada pelo `ApplicationController`.
- Registros pertencentes a usuários devem permanecer no escopo do usuário autenticado.
- Backups contêm dados sensíveis de usuários e informações financeiras.
- Somente administradores podem gerar backups do banco da aplicação.
- Mantenha `.env`, arquivos de backup baixados e credenciais de produção fora do controle de versão.
- A restauração do banco é uma operação administrativa ou de implantação e pode substituir objetos existentes. Leia o guia operacional e faça um backup separado antes de restaurar.

Consulte [Backup e restauração do banco](docs/operations/database-backup-restore.md) para o procedimento completo.

## Arquitetura e governança

- [Resumo da estrutura do código](docs/code-overview.md)
- [Fluxo de desenvolvimento](docs/governance/development-workflow.md)
- [Documentação de governança](docs/governance/README.pt-BR.md)

Todas as alterações devem usar uma branch dedicada, seguir os limites de aprovação documentados, preservar o isolamento dos dados dos usuários e incluir validação proporcional. A aprovação de commit, push e pull request são ações separadas.
