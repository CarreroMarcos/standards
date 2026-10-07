---
title: Supply Chain Security
version: "2.9"
scope: Supply chain security: dependencies, provenance, SBOM
consult_when: "When adding, upgrading, or reviewing a dependency, package, skill, or any third-party code — 'it's just a patch bump', 'the model recommended this package'."
last_reviewed: 2026-10-07
---

# Supply Chain Security

**Core principle:** a familiar name is not evidence of a clean artifact — resolve every suggested package at the registry before installing.

Applies to: adding, upgrading, or regenerating dependencies in AI-assisted development.

## Sections

- **The attack: slopsquatting** — hallucinated package names as the delivery mechanism
- **The second attack: poisoning the real package** — the 2026 worm wave through legitimate packages
- **Verify every suggested package at the registry — before installing** — resolve first, install second; release-age gating for new versions too
- **Treat the model as a supply-chain artifact** — pin model IDs; model change = dependency update
- **Make dependency additions explicit and pinned** — manifests and lockfiles, reviewed diffs
- **Adding a dependency is a last resort** — platform API, stdlib, or inline first; every dep traceable to a consumer
- **A dependency bump is a repo-wide, verified operation** — no ephemeral pins, every duplicate in one commit
- **Pin policy follows the audience** — exact pins internal, wide ranges published
- **Vendored and copied code is read-only** — no fixes to the baseline; small patches with upstream links
- **The artifact your gates measure against is a trust root** — eval corpora and ground-truth sets get lockfile treatment
- **The agent never adds a dependency on its own** — propose; human approves
- **Deny install-time execution by default** — scripts off, sandboxed installs
- **Treat agent config and skill supply chain as executable** — MCP servers and skills are supply-chain artifacts
- **Scan what you pull in** — what to scan and when
- **References**

## The attack: slopsquatting

AI assistants hallucinate package names. Research across 17 LLMs (2025) found that ~20% of AI-generated code samples referenced packages that do not exist. Of those, 43% recurred across multiple queries — meaning attackers can predict which names to register.

An attacker registers a hallucinated name on PyPI/npm, and `pip install <hallucinated-name>` installs their code. The hallucination is the delivery mechanism.

## The second attack: poisoning the real package

Slopsquatting is the 2025 threat. The 2026 threat is the real package going bad: maintainer-account compromise, CI/OIDC abuse, and trusted publishing minting malware with valid Sigstore provenance — provenance attests build identity, not source honesty.

The 2026 worm wave proved it: ChainDrop (Oct 2025), Mini Shai-Hulud (Aug 2026), and the axios compromise via TanStack (Sep 2026) all shipped hostile code through legitimate packages with valid provenance. Every check in the old playbook passed; the artifact was hostile anyway.

Treat every dependency update with the same suspicion as a new dependency. A familiar name is not evidence of a clean artifact.

## Verify every suggested package at the registry — before installing

Resolve the name against the official registry first:

```bash
pip index versions <package-name>  # Python
npm view <package-name> version    # Node
```

For a package name the agent is introducing: if it does not resolve on the official registry, do not install it. Resolve first, install second — no exceptions for "it looks legitimate" or a plausible repo URL. Dependencies already declared in the repo's manifest (including git, remote, and file deps) and packages on an approved internal mirror are a different case: verify them against the manifest/mirror, don't re-litigate their existence.

Check age and download history before first use — and gate new *versions* of familiar packages the same way. A fresh release of a trusted name is a new artifact; the version you approved last month says nothing about this one. A package registered yesterday with no dependents is not the same risk as an established one.

**Default gate: 14 days since release with download history that predates this release** — steady downloads across prior releases, not a day-one spike (a sharp, sustained uptick in downloads on a fresh release is itself a signal — the 2026 worm wave rode exactly that shape). Newer than the default needs explicit human approval with a stated reason (security fix, blocked feature), recorded in the dependency-change commit. "Explicit human approval" = a PR approval, a recorded decision, or a pre-registered policy covering the case (e.g. "critical CVE fixes are pre-approved") — the agent never self-approves. The number is a default, not a law — the human overrides it, never the agent alone.

## Treat the model as a supply-chain artifact

The plan's highest-blast-radius third party is often not a package — it is the model. A model can change server-side with no manifest diff, no registry to resolve against, no release age to gate, and no SCA scanner that sees it. It is the exact "familiar name, new artifact" attack this file warns about.

Pin and track model IDs in config (model name, version/date, endpoint, and behavior-affecting parameters such as effort and temperature). A model change gets a dependency update's suspicion and human approval — but a different reviewable unit. For model artifacts the reviewable unit is the *eval evidence*, not a line diff of outputs: output pins diff in version control, but megabytes of model prose are not human-reviewable, and a rubber-stamped diff is worse than no review. The ceremony is re-run + gate scoring + recorded human decision.

Detect drift via periodic re-runs against the pin: a pin mismatch on re-run opens a drift investigation. Silent model drift is a supply-chain incident — declare it *and* instrument for it.

Don't compare or average eval measurements across unidentified model versions. Log the served model version per capture run; before a re-run whose result will be compared or combined with an earlier one, verify the model identity matches. Server-side drift between two measurements invalidates the comparison with no signal — the average of two different models' scores is not a measurement.

Prompt bundles that steer model behavior are pinned artifacts too — a prompt change is a model-behavior change: reviewed diff (it *is* diffable, unlike model outputs), and the eval-pin re-run is the regression check.

Pins of model outputs record the model identity that produced them: model name, version/date or served-version marker, endpoint, effort config — alongside the content hash. For models pulled outside package managers (Ollama, direct download), pin the content digest, not just the name.

## Make dependency additions explicit and pinned

Route every new dependency through the manifest — `requirements*.txt`, `package.json`, lockfiles — so it arrives as a reviewed diff, never as a transcript of an `install` command. Pin versions; the lockfile records what actually resolved.

- **Large artifacts that exceed the repo's size gate live out-of-band with a tracked manifest** (pointer + sha256 + provenance); consumers verify before use and fail loudly on mismatch. Worked example: an eval pin manifest (`multi-pin-manifest.json`) whose scoring driver verifies the pin's sha256 + byte length before scoring.

## Adding a dependency is a last resort

**A new dependency is the last option, not the first** — inline trivial utilities, use the platform's own API (or the stdlib) over a wrapper package, and rule those out before proposing the addition. Every dependency must be traceable to a concrete consumer: "where is it used?"

- Why: every dependency is a trust and maintenance surface you carry forever. An agent defaults to the new-package solution because it minimizes *its* thinking, not your carried cost.
- Bad: `pip install <helper>` for a 20-line utility. Good: inline the helper, or use the stdlib and keep the surface yours.
- Boundary: the justification test — this rule decides whether an addition is warranted. The approval gate still applies ("The agent never adds a dependency on its own"). A platform-API-only rewrite that dwarfs the dependency's weight is not the cheaper option; compare total carried cost, not line counts.

## A dependency bump is a repo-wide, verified operation

**A version bump is an atomic, repo-wide, verified operation — never a single-line manifest edit.** Grep the entire repo for the old version value — build scripts, CI configs, Dockerfiles, deliberate assertion tables — and update every duplicate in one commit. Never merge a pin to an ephemeral artifact (preview tags, unmerged-PR builds): swap to the merged upstream SHA and verify prebuilt artifacts exist for every platform × flavor before merge.

- Why: a bump half-applied across manifests is two dependency sets pretending to be one — "it resolved on my machine" is not verification.
- For vendored bumps: rebase every local patch and verify fetch + patch + compile from a clean state. Verify the exact replacement upstream chose before mass renames — a plausible-but-wrong substitution multiplied across hundreds of files becomes a fixup measured in thousands of lines.
- Boundary: in a single-manifest repo the "repo-wide" sweep is one file — but the atomicity and verification bar stands.

## Pin policy follows the audience

**Pin exact versions in repo-internal manifests; keep ranges wide in published ones.** Repo-internal manifests (test fixtures, tooling, CI images) pin exact versions — never `^` or `~`, and never "tidy" an exact pin into a range. Published packages do the opposite: wide ranges or peerDependencies for toolchains the consumer already has, and runtime deps bundled into the shipped artifact — the end-user machine has no lockfile to read.

- Why: internal exactness buys reproducibility; published exactness buys breakage reports from users whose environments disagree with yours.
- Overrides/resolutions entries are load-bearing — find out what breakage one prevents before deleting it.
- Boundary: internal tools distributed as packages (a team CLI) are published-audience — pin wide there too.

## Vendored and copied code is read-only

**Vendored and copied code is read-only — it serves as a conformance baseline, not working code.** No style or typo fixes to vendored dirs, fixture copies, or pasted sources; exclude vendored dirs from mechanical rewrites and formatter passes. Vendor patches stay small, with a comment explaining the upstream behavior they correct plus the upstream issue link. Ship license attribution for copied open-source code in the same PR.

- Why: "fixing" vendored code silently diverges the baseline, and a formatter sweep across `vendor/` poisons every downstream diff with churn.
- Bad: formatter reformatting `vendor/` (hundreds of files of noise). Good: exclude vendored paths at the tool-config level so the baseline stays byte-identical to upstream.
- Boundary: patches are the sanctioned mutation path — small, upstream-linked, attributed. Anything bigger means re-vendoring from a newer upstream, not growing a fork.

## The artifact your gates measure against is a trust root

Eval corpora and ground-truth sets are the measuring stick every gate reads. Treat them like lockfiles: an owner (CODEOWNERS), reviewed diffs on every change, and a content hash asserted by a test — not just a count of cases.

- Why: if the measuring stick can drift silently, the gates pass on lies. A test that asserts totals but not content passes a corpus whose ground truth was flipped — the gates then measure against fiction.
- Scope: applies wherever a gate's verdict depends on pinned ground truth (eval corpora, golden files, benchmark fixtures). Does not apply to exploratory or throwaway test data.

## The agent never adds a dependency on its own

- New dependencies require explicit human approval — a PR approval, a recorded decision, or a pre-registered policy covering the case. The agent proposes with evidence; it never self-approves. "Do not install new dependencies without approval" belongs in the agent's guardrails.
- Dependency changes land as separate commits with a human-readable justification — what the package is, alternatives considered, what the lockfile diff shows. The agent prepares this evidence; it never approves its own addition.
- Put manifests and lockfiles under CODEOWNERS so the right eyes see every change. Pin manifests for large/eval artifacts (pointer + sha256 + provenance) get the same treatment — they are the trust root for the evidence the gates score.

## Deny install-time execution by default

Most 2026 supply-chain payloads fire at install time (preinstall/postinstall scripts). Shut that door:

- Install with scripts off by default (npm v12+ behavior; `--ignore-scripts` where the manager supports it). Note: `--ignore-scripts` alone is bypassable — prefer a manager version that defaults scripts off, or block git/remote/file deps explicitly.
- Run installs sandboxed and credential-free: no secrets in the install step's environment, no network beyond the registry.
- Some payloads fire at tool launch, not install — no install-time defense catches those. That is what the approval gate and config vetting below are for.

## Treat agent config and skill supply chain as executable

2026 payloads persist in agent config dirs and arrive as skills and MCP servers:

- `.claude/`, `.vscode/`, `SKILL.md`, MCP server configs, and hook definitions are executable surfaces — vet them like code. Supply-chain worms persist via SessionStart hooks and folderOpen tasks; uninstalling the package doesn't remove them.
- Vet every MCP server before connecting (audit tools exist); pin per MCP-SECURITY.md. The first malicious MCP server shipped in September 2025.
- Skills and MCP servers are supply-chain artifacts — pin them like dependencies and vet them like code. The vetting rules live in AGENTIC-SAFETY.md and MCP-SECURITY.md; don't duplicate them here.

## Scan what you pull in

Run Software Composition Analysis on dependencies:

```bash
pip-audit  # Python
npm audit  # Node
```

**Minimum CI requirement:** SCA scan (`pip-audit` or `npm audit`) on every change — merge request or direct push — that modifies `requirements*.txt`, `package*.json`, or `*.lock` files.

Run SCA from a pinned, trusted scanner version — scanners sit in the blast radius too, and a compromised scanner passed malware through in 2026.

**Enterprise environments:** route installs through an approved internal mirror (Artifactory, Nexus) — packages not in the mirror require explicit security review.

## References

Shai-Hulud npm worm lineage (2025–2026, incl. the axios-via-TanStack wave of Sep 2026 — valid Sigstore provenance on malicious packages: provenance proves build identity, not source honesty). @bitwarden/cli compromise (Apr 2026 — first payload explicitly hunting AI coding-tool credentials). postmark-mcp backdoor (Sep 2025 — first malicious MCP server in the wild). Clinejection (Feb 2026 — prompt injection drove an agent to run a malicious `npm install` in CI). ChainDrop worm (Oct 2025). Mini Shai-Hulud worm (Aug 2026).
