# Supply Chain Security

Applies to: adding, upgrading, or regenerating dependencies in AI-assisted development.

## The attack: slopsquatting

AI assistants hallucinate package names. Research across 17 LLMs (2025) found that ~20% of AI-generated code samples referenced packages that do not exist. Of those, 43% recurred across multiple queries — meaning attackers can predict which names to register.

An attacker registers a hallucinated name on PyPI/npm, and `pip install <hallucinated-name>` installs their code. The hallucination is the delivery mechanism.

## Verify every suggested package at the registry — before installing

Resolve the name against the official registry first:

```bash
pip index versions <package-name>  # Python
npm view <package-name> version    # Node
```

If the package does not exist on the official registry, do not install it. Resolve first, install second — no exceptions for "it looks legitimate" or a plausible repo URL.

Check age and download history before first use: a package registered yesterday with no dependents is not the same risk as an established one.

## Make dependency additions explicit and pinned

Route every new dependency through the manifest — `requirements*.txt`, `package.json`, lockfiles — so it arrives as a reviewed diff, never as a transcript of an `install` command. Pin versions; the lockfile records what actually resolved.

## Scan what you pull in

Run Software Composition Analysis on dependencies, especially after AI-assisted sessions:

```bash
pip-audit  # Python
npm audit  # Node
```

**Minimum CI requirement:** SCA scan (`pip-audit` or `npm audit`) on every merge request that modifies `requirements*.txt`, `package*.json`, or `*.lock` files.
