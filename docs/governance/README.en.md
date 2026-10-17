# Governance

This directory centralizes the project's development governance.

Use these files before any code change:

- `development-workflow.md`: mandatory workflow for analysis, planning, approval, implementation, review, and delivery
- `agents/`: role definitions for the development agents
- `templates/`: reusable templates for issue creation, implementation planning, and pull requests

Recommended order:

1. Open the issue template.
2. Fill the implementation plan.
3. Create a branch using the documented naming convention.
4. Execute the change only after explicit approval.
5. Close the work with the PR template and final checklist.

Approval to implement, commit, push, and open a pull request are independent.
Approval of an implementation or checkpoint does not automatically authorize Git operations.

Commits and delivery:

- request separate explicit confirmation before creating each commit
- request explicit confirmation before running `git push` or opening a pull request
- without confirmation, keep changes local and report the current state

Language:

- [Português](</home/nal/code/BernardoNal/money-control/docs/governance/README.pt-BR.md>)
- [Back to selector](</home/nal/code/BernardoNal/money-control/docs/governance/README.md>)
