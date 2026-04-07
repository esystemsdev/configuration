# Developer setup: two-stage model

## Purpose

Define how the **public** `configuration` repo and the **private** `dev-config-internal` repo divide responsibility, how installers and **published docs** stay aligned, and what work remains—including **version-pinned** distribution so bootstrap scripts are not fetched from a moving `main` branch.

---

## What this repository already delivers (must stay in scope)

The plan applies to the **actual** onboarding surface, not a greenfield installer. These assets and guides are authoritative today:

| Category | Items |
|----------|--------|
| **Persona guides** | [Setup-developer.md](Setup-developer.md) (full stack, WSL or macOS), [Setup-integration.md](Setup-integration.md) (integration specialist, lighter tool set) |
| **Entry / index** | [README.md](README.md) (paths, quick reference, repo contents list), [DEVELOPER.MD](DEVELOPER.MD) (internal pointers where used) |
| **Deep-dive docs** | [docs/SetupDeveloperEnv.md](docs/SetupDeveloperEnv.md), [docs/SetupGitEnv.md](docs/SetupGitEnv.md), [docs/SetupWslUbuntuDev.md](docs/SetupWslUbuntuDev.md) |
| **Windows bootstrap** | `SetupDeveloperEnv.ps1`, `SetupDeveloperEnv.yaml`, `SetupWslUbuntuDev.ps1`; optional `SetupGitEnv.ps1` for clone/npm flows |
| **macOS / Unix** | `SetupDeveloperEnv.sh` (same YAML as Windows), `SetupGitEnv.sh` |
| **Downstream** | Users are directed to `@aifabrix/builder`, `aifabrix dev init`, infra/platform commands, and (in guides) fixed clone lists or `SetupGitEnv` env vars |

Any change to “stages,” config-driven repos, or internal-only layers **must** update these docs and snippets together so Windows download steps, macOS clone steps, README quick reference, and detailed `docs/` pages do not contradict each other.

---

## Versioned distribution (correct source for raw downloads)

### Problem

Several guides use **raw.githubusercontent.com** with the **`main`** ref, for example:

- `Setup-developer.md` — Step 1 downloads `SetupDeveloperEnv.ps1`, `SetupDeveloperEnv.yaml`, `SetupWslUbuntuDev.ps1` from `.../configuration/main/`.
- `Setup-integration.md` — same pattern for `SetupDeveloperEnv.ps1` and `SetupDeveloperEnv.yaml`.

That always tracks the tip of `main`. It is **not** reproducible: two machines run at different times may get different script behavior; support and security reviews cannot assume a single artifact set.

### Requirement

- **Pin bootstrap downloads to an explicit version** (Git **tag** or release ref that matches what you ship), e.g. `1.1.0`, not `main`.
- **URL shape:** `https://raw.githubusercontent.com/esystemsdev/configuration/<REF>/<file>` where `<REF>` is the tag (or a named release branch if policy requires it)—consistent across all docs that use raw download.
- **Single source of truth:** Define how the version is chosen and documented:
  - Prefer one **documented variable** in snippets (e.g. `$configurationVersion = "1.1.0"` in PowerShell, or a short “replace `VERSION` below” note) so maintainers bump one place per release—or generate snippets from a small manifest in-repo if you add automation later.
- **Release discipline:** When tagging `configuration`, verify that the same tag is reflected in every raw-URL snippet (`Setup-developer.md`, `Setup-integration.md`, and any duplicate in `README.md` or elsewhere).

### Planned doc / snippet work (tracked by this plan)

- Replace `main` with the pinned ref in all raw download examples.
- Add a one-line note in the onboarding guides: *these files are loaded from release `<version>`; for latest development clone the repo instead.*

---

## Context: two-stage model (unchanged intent)

1. **Public bootstrap** — runs on a largely blank machine; scripts inspectable before run.
2. **Internal setup** — private repo access and company-specific settings (internal URLs, Twingate, team defaults); after base tooling exists.

The public stage stays **vendor-neutral** in design (no hard lock to one Git host in *schema*). The **Builder CLI** remains runtime/developer tooling—not the owner of “which repos to clone” long term; clone orchestration stays in setup repos and docs.

**Note:** The repo already expresses two **public** personas (full developer vs integration) in separate markdown guides. The **internal** layer (`dev-config-internal`) is additive; it must not orphan the existing guides.

---

## Current baseline (summary)

- Public **`configuration`** ships the scripts and YAML above plus the linked documentation.
- Windows paths often use **`C:\Setup`** + raw download **before** Git is fully used; macOS paths often **clone** `configuration` first—both flows must stay documented and version policy must cover **both** (pinned raw URLs where used; clone can use `git checkout <tag>` guidance if you want parity).

---

## Target architecture

### Layer 1 — Public bootstrap (`configuration`)

- Same deliverables as today, plus **version-pinned** distribution where files are downloaded without a prior clone.
- May evolve toward config-driven public repo lists (see below) without removing the existing `SetupGitEnv` / manual clone documentation until replaced explicitly.

### Layer 2 — Internal setup (`dev-config-internal`)

- Company-private config and optional scripts; reuses or extends public patterns.
- Internal README is the single entry for staff-only steps.

---

## Design principles

| Area | Requirement |
|------|-------------|
| **Trust** | Public scripts stay readable; prefer config files over magic constants. |
| **Reproducibility** | Raw downloads use a **tagged ref**, not `main`. |
| **Docs coherence** | README, Setup-developer, Setup-integration, and `docs/*.md` stay aligned with what ships and which version. |
| **Config-driven repos** | Longer term: repo lists from config where appropriate; public vs private lists split across repos. |
| **Separation** | No secrets in public repo; no live private URLs in public default config. |
| **Resilience** | Missing private access should not break public-only onboarding. |
| **Builder CLI** | No moving bootstrap orchestration into Builder. |

---

## Required changes (work themes)

1. **Version-pinned raw URLs**  
   Update all guides/snippets that use `raw.githubusercontent.com/.../main/` to use an explicit **release ref** and document the bump process with releases/tags.

2. **Explicit stages in installer narrative and code**  
   Stage 1 = public bootstrap; stage 2 = internal/private—reflected in README and internal repo without contradicting existing persona split.

3. **Config-driven repository sourcing (incremental)**  
   Public installer or companion config for **public** repos; private lists in `dev-config-internal`. Until implemented, keep current `SetupGitEnv` / documented clone lists as the documented truth.

4. **Thin private layer**  
   Extend or compose public behavior; avoid duplicating entire script trees.

5. **Installer UX**  
   After stage 1: clear next steps; optional private reachability hints; no harsh failure for public-only users.

6. **Documentation pass**  
   Any structural change updates **all** affected files listed in “What this repository already delivers.”

7. **Backward compatibility**  
   Users who bookmarked `main` URLs may need a short migration note (“pin to tag X or clone the repo”).

---

## Discovery checklist (before implementation)

- All locations that embed `raw.githubusercontent.com` and the ref segment (`main` vs tag).
- Whether `README.md` duplicates download snippets (keep in sync with persona guides).
- Entrypoints: `SetupDeveloperEnv.*`, `SetupWslUbuntuDev.ps1`, `SetupGitEnv.*`.
- Where clone lists live (markdown only vs scripts) and overlap with future YAML repo lists.

---

## Deliverables

1. **Versioned bootstrap:** Snippets and any central “current release version” note; tags used consistently.
2. Updated public installer flow and messaging where stages are clarified.
3. Public config model for optional repo bootstrap (when implemented), with examples.
4. Private setup structure in `dev-config-internal` as appropriate, with one primary internal README.
5. README + Setup-developer + Setup-integration + relevant `docs/*.md` updated in **one** coherent change set per release where URLs or stages change.
6. Backward compatibility notes for `main`-based bookmarks.
7. Example public/private configs (sanitized) when the config-driven work lands.

---

## Illustrative layout (aligned with repo today)

**`configuration` (public)**

- `SetupDeveloperEnv.ps1`, `SetupDeveloperEnv.sh`, `SetupDeveloperEnv.yaml`
- `SetupWslUbuntuDev.ps1`
- `SetupGitEnv.ps1`, `SetupGitEnv.sh`
- `Setup-developer.md`, `Setup-integration.md`, `README.md`, `docs/*.md`
- Optional future: `config/public-repos.yaml` (or equivalent)—must be referenced from the guides above

**`dev-config-internal` (private)**

- Internal scripts/config and `README.md` for stage 2

---

## Functional requirements

- Public step works on a documented minimal machine; raw downloads must resolve to **immutable-by-tag** content for a given release.
- Internal step assumes Git and stage-1 outcomes per README; graceful behavior without private access.
- No secrets in public repo; no live private URLs in public default config.

---

## Nice-to-have

- Dry-run / verbose flags on installers.
- Optional private-repo reachability check.
- Profiles (public / core / sdk / full) for repo bundles.
- Automation to assert docs’ pinned version matches `git describe` or `package`/tag file at release time.

---

## Suggested execution order

1. **Inventory** all raw URLs and clone instructions; list every file that must change when the pin bumps.
2. **Define** the release ref policy (tag per release; how docs cite it).
3. **Edit** `Setup-developer.md`, `Setup-integration.md`, and any other files using `main` in raw URLs; align README if needed.
4. Continue with stage separation and config-driven repos as separate increments, each time updating the **full** doc set from the table above.
5. Close with what shipped, current pinned version, and follow-ups.

This document is the **plan and specification**; implementation work is tracked against the deliverables and the existing documentation inventory.

---

## Applied (documentation pass)

The following shipped in-repo to satisfy the version-pinned distribution and doc-coherence themes:

- **Pinned ref `1.1.0`** in raw-download PowerShell snippets (`$configurationVersion` + `raw.githubusercontent.com/esystemsdev/configuration/<ref>/`) in `Setup-developer.md` and `Setup-integration.md`.
- **README.md:** two-stage model, bootstrap release pinning table, bump reminder, backward-compatibility note for old `main` URLs, quick-reference alignment.
- **Persona guides:** stage 1 / stage 2 narrative; integration guide includes the “release vs clone for latest dev” line.
- **macOS:** optional `git checkout 1.1.0` after clone in `Setup-developer.md` (parity with pinned downloads).
- **`DEVELOPER.MD`:** short pointer to stages.
- **`docs/SetupDeveloperEnv.md`**, **`docs/SetupWslUbuntuDev.md`:** pointers to README pinning section.
- **`dev-config-internal/README.md`:** stage-2 entry and relationship to public **configuration**.

**Not done in this pass (future increments per plan):** config-driven `public-repos.yaml`, dry-run/reachability automation, release assertion tooling.
