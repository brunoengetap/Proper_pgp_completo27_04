# Backlog de Execução por Sprint — Proper PGP

## Premissas de escopo confirmadas
- `machineKey()` não será alterada.
- `pgpMachineKey()` não será alterada (inclusive em eventual deduplicação de definição, preservando algoritmo/saída).
- `proper_admin_v2` será preservada.
- Login, PDF, fotos e sessões salvas ficam fora de escopo funcional (somente integração sem mudança de fluxo).
- Implantação incremental, faseada, testável e com rollback.

## Convenções de priorização
- **P0**: bloqueia consistência de dados e riscos de regressão alta.
- **P1**: melhora robustez operacional e governança.
- **P2**: melhoria de UX e observabilidade.

## Sprint 0 — Inventário e baseline contratual (P0)

### Objetivo
Congelar o comportamento atual e formalizar contratos de payload antes de mudanças comportamentais.

### Itens
1. **Mapear payloads atuais do Campo** (inspeção, preventiva, offline/replay).
2. **Catalogar funções duplicadas/sobrepostas** no Campo com risco e dependências.
3. **Definir contrato de schema_version/request_id/tipo** para evolução compatível.
4. **Documentar estratégia de rollback por feature flag** (alert-only vs bloqueio).

### Critérios de aceite
- Existe documento com payloads reais por fluxo.
- Existe matriz de risco por função crítica com owner.
- Existe contrato de versão de payload aprovado.

### Testes
- Snapshot de payloads gerados em cenários reais.
- Replay controlado de fila offline sem alteração de comportamento.

### Rollback
- N/A (fase documental).

---

## Sprint 1 — Deduplicação segura e mínima (P0)

### Objetivo
Reduzir duplicidade com bloqueio forte apenas quando há evidência forte.

### Itens (Campo)
1. **Deduplicar funções sobrepostas sem alterar algoritmo** de identificação.
2. **Cadastro rápido com validação progressiva**:
   - bloquear apenas com colisão forte;
   - alertar em similaridade fraca.
3. **Checagem local de duplicidade** por serial/tag/machine key (sem alterar `pgpMachineKey`).

### Itens (GAS)
1. **Validação canônica de cliente** com bloqueio forte por CNPJ.
2. **Validação canônica de máquina** por prioridade:
   - serial > tag no cliente > machine key > combinação fraca (alerta).
3. **Idempotência base por request_id** para gravações críticas.

### Itens (Admin)
1. **Painel de suspeitas de duplicidade** por categoria (cliente/máquina/modelo/peça).
2. **Badges de severidade**: bloqueado, alerta, legado.

### Critérios de aceite
- Colisão por CNPJ ou serial não cria novo registro.
- Similaridade fraca não bloqueia, mas gera alerta auditável.
- Reenvio da mesma request não duplica efeitos.

### Testes
- Cliente duplicado (mesmo CNPJ, nome divergente).
- Máquina duplicada (serial repetido; tag repetida no mesmo cliente).
- Reenvio duplicado de payload idêntico.

### Rollback
- Feature flag para modo **alert-only**.

---

## Sprint 2 — Separação rígida inspeção vs preventiva (P0)

### Objetivo
Impedir mutações indevidas de estado em fluxos de inspeção.

### Itens (Campo)
1. **Padronizar payload com tipo obrigatório** (`inspecao`/`preventiva`).
2. **Pré-validação por tipo** antes de envio e antes de entrar na fila offline.
3. **Fila offline versionada** com reconciliação tolerante a payload legado.

### Itens (GAS)
1. **Validação centralizada por schema**.
2. **saveVisit imutável** com tratamento de legado (`tipo` vazio -> `inspecao_legado` na leitura).
3. **savePreventiva/updateMachineParts** só alteram estado quando ação compatível (ex.: `trocada`).

### Critérios de aceite
- Inspeção nunca altera `MACHINE_PARTS`.
- Preventiva só altera estado com ação válida.
- Payload legado continua processável sem quebrar sync.

### Testes
- Inspeção pura.
- Preventiva com peça trocada.
- Preventiva com peça conferida.
- Reprocessamento offline após retorno de conectividade.

### Rollback
- Manter validação estrita no GAS e afrouxar apenas pré-validação do Campo.

---

## Sprint 3 — Governança de catálogo modelo→peça→máquina (P1)

### Objetivo
Formalizar relacionamentos e reduzir ambiguidade de referência.

### Itens
1. **Admin: telas de relacionamento** peça↔modelo↔máquina.
2. **GAS: consultas canônicas** de aplicação por modelo e histórico por máquina.
3. **Detecção de duplicidade textual** (normalização) apenas para sugestão humana.

### Critérios de aceite
- É possível auditar rapidamente “qual peça aplica em qual modelo/máquina”.
- Inconsistências aparecem com score de confiança.

### Testes
- Consultas cruzadas de relacionamento.
- Casos de variação textual de marca/modelo.

### Rollback
- Leitura legada paralela por versão de contrato.

---

## Sprint 4 — Auditoria e merge manual assistido (P1)

### Objetivo
Corrigir histórico sem merge automático agressivo.

### Itens
1. **Wizard de merge manual** com pré-visualização e impacto.
2. **Log transacional de merge** com reversão assistida.
3. **Relatório de impacto pré-aplicação** (dry-run obrigatório).

### Critérios de aceite
- Nenhum merge ocorre sem confirmação humana.
- Toda operação possui trilha de auditoria e rollback.

### Testes
- Dry-run com cenários de conflito.
- Rollback integral pós-merge.

### Rollback
- Reversão por log transacional.

---

## Sprint 5 — UX complementar e observabilidade (P2)

### Objetivo
Reduzir erro humano no campo e melhorar transparência operacional.

### Itens
1. **UX de alerta contextual** em cadastro e preventiva.
2. **Indicadores de saúde** (duplicidade, legados sem tipo, fila pendente/reprocessada).
3. **Métricas de sucesso de sync offline** com reconciliação.

### Critérios de aceite
- Queda de erros de cadastro em cenário piloto.
- Painel de saúde com métricas acionáveis.

### Testes
- Testes de usabilidade guiada.
- Simulação de fila cheia e reenvio em lote.

### Rollback
- Toggles de interface e métricas não bloqueantes.

---

## Matriz de decisões pendentes (antes da Sprint 1)
1. **Política de bloqueio vs alerta** por entidade (cliente/máquina/modelo/peça).
2. **Cadastro de máquina sem serial/tag**: permitido ou não; em que condições.
3. **Cadastro de cliente sem CNPJ**: política e SLA de revisão.
4. **Momento de remoção de ação padrão em peça**: imediato (Sprint 2) vs gradual.
5. **Legado sem tipo**: migração física de base vs tratamento somente em leitura.

## Definition of Done (global)
- Compatibilidade preservada com `proper_admin_v2`.
- Fluxos de login, PDF, fotos e sessões salvas sem regressão funcional.
- Sem alteração de algoritmo/saída de `machineKey()` e `pgpMachineKey()`.
- Toda mudança com teste de regressão de sync offline + idempotência.
