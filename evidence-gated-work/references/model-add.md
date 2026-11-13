# Appendix: adding a released model id

## Curation rule for name literals

Model-name aliases list the models a user would pick. They are not catalogs.

- Per provider line (tier name), list the newest id of the newest generation and the newest id of the previous generation. Remove the older id the new one replaces, in the provider alias and the global list.
- Leave out dated snapshots that have an undated alias, previews a GA id superseded, floating `-latest` aliases unless they are canonical for that provider, and non-chat models.
- On hosted cloud marketplaces, list one id per model, preferring the widest inference profile that exists.
- Keep every id a docs alias resolves to, even when the rule above would drop it; a parity test will fail otherwise. Changing an alias target is a separate decision.

Profiles match any id, so removing an id from a literal changes autocomplete only. Never remove a profile branch because its id left a literal.

**Image models** are a separate public surface. If the model is consumed by an image generator, update the image literal, the direct provider adapter, and its tests; do not widen to conversational names, profiles, or gateway aliases unless that surface is explicitly supported and in scope. Keep provider-agnostic controls in shared settings; put model-specific size/aspect geometry in a private helper and update the public support matrix. Verify geometry against official documentation; if the provider publishes no exact output shapes, probe every documented aspect/resolution combination and record the evidence. Prefer deterministic table tests for the matrix; one representative recording only where integration coverage is genuinely needed.

## 1. Verify the model exists at the provider

Never trust marketing names, news articles, or guesses. Hit the provider's model-listing endpoint with credentials from the repo-root `.env`. For region-scoped catalogs, query the region actually deployed. List **every** id the provider exposes for this release; add only what exists, do not extrapolate sibling variants. If the user-given id is absent, stop and confirm.

## 2. Mirror the most recent add-model change for that provider

Find the smallest, most recent such commit for the same provider. Its file list is the **floor** of what you will touch, rarely the ceiling.

## 3. Enumerate readers (load-bearing)

For every variable, tuple, and literal you will touch, search its readers across the repo. This catches the snapshot and enumeration tests that ratchet on every model add; skipping it pushes work onto CI and produces broken changes. Classify each hit: must update, snapshot to refresh, or skip (recorded cassettes, docs about unrelated models). If search output looks mangled, drop to a plainer tool — do not push past garbled output.

Public-API compatibility gates report literal changes as attribute-value changes; the project's allowlist usually covers added and removed names. Do not add a waiver for a change the gate already passes; a waiver for an unused symbol makes the gate fail.

## 4. Pricing and context data

Pricing usually belongs to an automated feed, not a manual counterpart change. Verify ids and hosting independently of pricing data; never infer availability from an older sibling or a pricing match. Do not block name support on feed lag. When no price entry exists, cost raises and a cost limit cannot be enforced; when no context window is known, usage reads null. Report a missing or stale entry and link the automation that owns it.

## 5. SDK lag

Curated literals are usually tied to the locked SDK's own literal by a test. Check whether the locked SDK lists the new id:

```bash
uv run python -c "from <sdk> import <ModelLiteral>; from typing import get_args; print([m for m in get_args(<ModelLiteral>) if '<new-version>' in m])"
```

If it does not, add the id to that entry's bridge list and remove the bridge in the change that bumps the SDK past the release listing it. A lock upgrade that changes an SDK literal makes the snapshot test fail: review the new ids against the curation rule, update the aliases, drop any bridge now listed, then fix snapshots.

## 6. Probe capabilities only if it is not a pure mirror

A sibling in an existing family needs only the prefix added to the dispatch. A new family or unclear capabilities needs a small comparison script hitting the new model and its closest neighbour with sampling params, reasoning-effort values, new parameters from the release notes, and streaming/tool calls. Diff the responses; anything that diverges belongs in the profile.

Read the provider's migration guide's breaking changes before probing. Those list every divergence from the previous model, and they tell you what to probe.

## 7. Edit minimally

Make only the changes enumeration surfaced. Resist scope creep. A suspected pre-existing bug in a sibling: reproduce it live first; fold it into the change only if reproduced, with a test and one line in the description; otherwise flag it in the description. When snapshots change, verify the diff is the expected literal addition only.

## 8. Integration recordings

Default for mirror-only adds: no new recording. The project typically keeps one representative model per family, and the profile unit test is sufficient. When the model introduces a meaningful request/response shape change, tag the new id onto an existing parametrized recording list rather than writing a new test; prefer an existing provider subdirectory if one exists, never create one speculatively.

## Landmine categories you will hit

Each of these is a shape, not a specific model — check them for every new id:

- **Prefix-ordering dispatchers.** A prefix-keyed table resolved first-match-wins: a more specific prefix must precede the broader one it would shadow, and a newer family must precede the catch-all. Miss it and the model silently falls through to "no reasoning," wrong defaults, no error. A **dotted point release matches none of its family's prefixes** — it must be added explicitly.
- **Silent inheritance in `startswith` tuples.** A point release inherits every flag of its base id; tests stay green and nothing warns. The only way to find a divergence is the migration guide plus a side-by-side probe. Where a flag must not carry over, carve the id out explicitly.
- **Curated Codex/TUI menus** kept in a separate package: add the id there when the tool offers it, exercise it with a real login, and update every mirror of that list.
- **Image quality and geometry probing.** Validate size before quality — an invalid size returns a generic list that tells you nothing. Probe geometry with out-of-bounds sizes; identical rejection messages mean same family.
- **"Responses: not supported"** on a model page often refers to the top-level model, while a tool call path still accepts the id. Probe the tool before deciding the image literal.
- **Forced tool choice** divergences are per-model; probe forced choice against the new id and its neighbour to tell a genuine divergence from a thinking-only constraint.
- **Pricing fallthrough**: a point release falls into its base model's price entry and returns the old price with **no error**. Check computed price against the published rate.
- **Marketplace inference profiles** must be listed separately from foundation models; a model may launch with only a global profile and no regional one.
- **Gateway parity**: if the gateway proxies the provider, it reaches the canonical API through an ordinary client with a proxy base URL. Assume it serves every new id; never add a new id to an unsupported list. File one tracking issue per release listing every id, including those the curation rule keeps out.
- **Marketplace access gates**: a catalog can list a model while the API answers access-denied for your account. List the id anyway; keep capability gates on existing prefixes; file one tracking issue listing the probes to run once access is granted. Change a gate only after its probe passes.
- **Docs aliases**: docs name models through aliases, not ids. Repoint an alias when the placement rules say the new model belongs there; do not wait for the gateway.

## Update this appendix

When a model add surfaced anything not already documented — a new ratcheting test, a dispatch tuple, a misleading SDK behavior, a misconception — add it here before closing the session.
