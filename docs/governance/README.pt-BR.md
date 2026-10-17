# Governança

Este diretório centraliza a governança de desenvolvimento do projeto.

Use estes arquivos antes de qualquer alteração de código:

- `development-workflow.md`: fluxo obrigatório para análise, planejamento, aprovação, implementação, revisão e entrega
- `agents/`: definição dos papéis dos agentes de desenvolvimento
- `templates/`: modelos reutilizáveis para criação de issue, plano de implementação e pull request
- `../code-overview.md`: visão curta da estrutura do código e dos pontos de atenção arquiteturais

Ordem recomendada:

1. Abrir o template de issue.
2. Preencher o plano de implementação.
3. Criar uma branch usando a convenção documentada.
4. Executar a alteração somente após aprovação explícita.
5. Encerrar o trabalho com o template de PR e o checklist final.

Autorizações de implementação, commit, push e pull request são independentes. A aprovação
da implementação ou de um checkpoint não autoriza automaticamente operações no Git.

Documentação de código:

- manter simples e próxima de áreas relevantes do projeto
- documentar decisões de domínio, regras de escopo por usuário e pontos de expansão arquitetural
- evitar comentários redundantes ou linha a linha

Commits e entrega:

- pedir confirmação explícita separada antes de criar cada commit
- pedir confirmação explícita antes de executar `git push` ou abrir uma pull request
- sem confirmação, manter as alterações locais e informar o estado atual

Idioma:

- [English](</home/nal/code/BernardoNal/money-control/docs/governance/README.en.md>)
- [Voltar ao seletor](</home/nal/code/BernardoNal/money-control/docs/governance/README.md>)
