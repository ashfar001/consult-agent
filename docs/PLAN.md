# ConsultAgent: master plan

Windows workstation agent (Flutter, `agent/`) for a construction consultancy. Backend is built separately; the agent runs against the contract in the root README and a mock API.

## Module execution order

| NN | Plan | Summary |
| --- | --- | --- |
| 00 | (built) Phase 1 scaffold | Config, drift DB v1, models, MockApiClient, login, project select. See git history. |
| 01 | [CAD-triggered sessions](plans/01-cad-sessions/00-README.md) | Prompt on CAD launch, timer, lunch break, 5 PM cut-off + overtime, files, backup, end of day; builds on 00 |
