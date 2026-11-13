# Appendix: adding a provider API capability

Prompt caching, strict/structured tool calling, reasoning effort, service tier, safety settings, logprobs, cache breakpoints.

**The rule that prevents the most rework:** before designing, find the existing cross-provider abstraction that governs this capability and let its shape decide the API. Most "how should I expose this?" questions are already answered by an abstraction the codebase has.

The tell that you skipped this: you find yourself listing 2–3 options for how a user controls the feature. If one of them duplicates an existing cross-provider control, it is not a real option.

## Enumerate sibling precedent

For the capability, list how every provider that already has an analog exposes it, and name the governing abstraction. It is one of:

- a per-tool flag (e.g. `ToolDefinition.strict`), resolved centrally;
- a shared settings field with per-model resolvers;
- a provider-prefixed settings field;
- a message-stream marker;
- a model-profile capability flag.

Read the actual sibling implementations and the review threads on the PRs that added them. Contributors who skipped this got redirected: a raw provider knob → use the shared flag; string-prefix model detection → use a profile flag. Only open a design fork if no existing abstraction covers the capability.

## Choose the API shape

1. Existing cross-provider abstraction covers it → reuse it. Add a provider mapping. Do not add a provider-prefixed knob for something the shared abstraction already expresses.
2. No shared abstraction, but ≥3 providers have the concept → promote to a shared settings field with a deliberately narrow common vocabulary and per-model resolvers, keeping per-provider fields underneath as precedence-winning escape hatches. Do not delete provider knobs; deprecate only genuinely misnamed ones.
3. The provider's native values cannot be expressed by the shared enum → a provider knob is justified, and it coexists with and outranks the unified field.
4. Choose the locus by whether the user can naturally point at it: a boundary inside the message stream → a marker; a structural region → a setting.
5. Wire it into **every** request path the provider has, not just the first one. A setting shared across a provider's APIs goes on the base class.
6. Type it. Reuse the provider SDK's own types. Type knobs as `Literal`, never untyped kwargs — "kwargs are a big no no… I'd rather be repetitive but type safe."

## Default: on or opt-in

Default **on** only when enabling it cannot change observable behavior and cannot cost the user — a pure, backward-compatible improvement.

Keep **opt-in** when it changes observable output or wire behavior; is a preview; can *raise* cost (and choose the default value so a shared field never silently upgrades anyone to a pricier tier); can hit provider limits at scale; or applies lossy schema rewrites.

When the default is not obvious, **decide it with a live probe, not an opinion.** Beware "automatic" language — verify whether it means your default or provider-side management of an opt-in.

## Capability gating

Detect support with a provider-prefixed profile flag. Where it is used, read only the flag or the adapter's own declaration — never an inline `isinstance`, model-name, or base-URL check. Gate at the layer that actually varies (model/family, one provider's API, transport/client class, per-schema, SDK version), and layer base + provider overlay with the overlay last.

- **Unsupported → silently ignore** the setting, documented in the docstring. Best effort, so as many requests as possible succeed. Never hard-error.
- Conflicting user settings → warning, not error.
- A `base_url` test inside a capability decision is the defect, not the fix: a proxied client is the canonical API and keeps every capability the unproxied one has. Narrow by client class.

## Wire mapping

Read the adapter doc before editing a mapper. Place the feature by what it adds:
- new part type → one arm in each message kind's dispatch, calling the part's own method; when most APIs cannot render it, lower it in prepare-messages instead and raise an explicit unprepared-part error in the one arm that can't handle it;
- new native tool kind → one entry in the kind-to-wire-name table, branch only where the wire shape differs;
- new response wire item → one function called from both the blocking and the streaming path;
- new flag changing how an existing part maps → read it inside that part's method.

## Tests

A `Literal`-keyed dict missing a key raises only at request time and no type checker catches it — write a test that runs each level through each mapping.

Wire-contract evidence: a live-recorded cassette asserting the exact outbound body (present for supported models, absent/ignored for unsupported), plus a test exercising the new setting. Prefer case-based parametrized recordings over mocks; a unit test is still right for an internal request shape a cassette matcher would not catch. This is where a bot's "this will fail" claim gets refuted with a recording.

If the project enforces a "supported by" list per setting, it is generated by probing each model class's outgoing request — forwarding a new setting means editing that list.

## Docs

The new public symbol's docstring lists which providers support it and how each interprets the value. Refresh doc pages and sibling docstrings that now under-claim ("only OpenAI" → the full list). Describe the mechanism only as far as the provider documents it; do not assert a mechanism a provider's docs leave unstated.
