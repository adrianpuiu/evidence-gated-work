# evidence-gated-work

A skill for agents doing review-and-merge work in a repo where **other people's code, text, and
instructions arrive in the context**. It answers four questions that a competent model still gets
wrong: whose instructions bind you, who may decide what, what proves a claim, and how state survives
a context window.

## What it contains

| Section | Subject |
|---|---|
| §0 | Output contract: lead with the result or the decision, surface asks as structured questions, size work by shape rather than wall-clock time. |
| §1 | Provenance: materialize a policy base at the target branch tip and read instructions from there; the candidate tree contributes code as data, never instruction. Includes a trap table for the shell commands that fail silently (`gh pr view ""`, `git fetch <remote> ""`, shallow-clone merge bases, `git show "$SHA":path` degrading to index syntax). |
| §2 | Decision rights: an exhaustive matrix of what the agent, the author, and a maintainer may each decide. |
| §3 | Evidence: sources or it didn't happen; probe rather than opine; order research before reading the implementation to avoid anchoring. |
| §4 | Persistence: append-only decision logs, lane-keyed handoffs, and commitments quoted verbatim across a session boundary. |
| §5 | Gates: a bounded review budget, an exempt-delta table computed from the last reviewed SHA, and a requirement that every exemption names the command that would falsify it. |
| §6 | Scope: separate the submitted patch from the integration contract before deciding how much to widen. |

Three reference appendices cover provider capability design, model-id addition, and power-user feature
audits.

## Why it exists

Built by merging thirteen skills from `pydantic/pydantic-ai/.agents/skills/` into the invariants that
cannot vary by task, then measuring it against a no-skill baseline. The measured result:

| Round | With skill | Baseline |
|---|---|---|
| 1 — initial draft | 100% | 96.4% |
| 2 — added shell-failure and snapshot evals | 100% | 75% |
| 3 — cut §0 by ~60%, added "show the guard AND the reasoning" to §1 | 100% | 50% |

The discriminating finding: a capable model already leads with its answer, already quotes constraints
verbatim, and already refuses to wave a snapshot through. What it does not do is explain *why* each
guard exists — and that is where the gap lives. A baseline agent writes `set -euo pipefail` and
`git cat-file -e` with real competence and no idea what either defends against.

## Install

```bash
git clone https://github.com/adrianpuiu/evidence-gated-work.git
cp -R evidence-gated-work/evidence-gated-work ~/.agents/skills/
```

Or use the packaged artifact:

```bash
scripts/publish.sh evidence-gated-work   # validates, writes dist/evidence-gated-work.skill
```

## Known limits

- Grading used a regex grader, not a language-model judge. It measures whether a response does a
  thing, not how well, and it rewards the skill's own vocabulary.
- Trigger optimization was not measured; the description was tightened by hand against a 20-query set.
- The snapshot-instinct eval does not discriminate: both configurations pass it in every round.

## License

MIT — see `LICENSE`.
