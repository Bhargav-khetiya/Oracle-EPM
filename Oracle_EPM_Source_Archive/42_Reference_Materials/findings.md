# Review Findings and Checkpoint

**Checkpoint:** 2026-10-30. **Scope:** Oracle EPM Docs with Examples - Copy. This is a progress record, not a completion claim.

## Baseline
Initial inventory: 688 files before this review folder (677 Markdown, 7 text, 2 Calc Manager example files, 1 JSON settings file, 1 PowerShell organizer script). Markdown corpus ~5.51 MB. The extracted Planning administration manual is ~2.2 MB and is not fully read. See [coverage.csv](coverage.csv) for file status.

## Safety and findings
- No AGENTS.md or project instructions were found in the project/checked parents.
- Git status was unavailable. Back up changed files under _review/backups/2026-10-30/.
- .vscode/organize_docs.ps1 was inspected, not run: it moves/removes files and targets the similarly named folder without “- Copy”.
- Initial SHA-256 scan found no exact duplicate Markdown files.
- Notes include unverified claims about Cloud internals and universal performance (physical files, internal schemas/routines/network details, fixed block sizes, benchmark/tuning figures). Require support or historical/on-premises qualification.

## Read coverage
Root README and master index were read and rewritten with explicit boundaries; originals backed up. Eighteen subject indexes were read end-to-end. Also inspected .vscode settings/script, two .csc examples, and Calc Managers all business Rule Functions.txt. Raw extracts and two large Oracle text sources were only partially inspected. Detailed documents remain unread; tracker is authoritative.

## Link audit baseline
Scan of 677 baseline Markdown files found 2,492 destinations: 1,767 relative and 112 absolute local links to the non-Copy sibling folder. 580 relative links did not resolve under scan rules; 433 had one same-basename candidate. One absolute target points to the Planning manual at an obsolete location. Candidate basename is not enough to establish intent. No bulk repair is claimed.

## Oracle research
See [oracle_sources.md](oracle_sources.md). “Used” means an Oracle page was examined for the stated boundary, not that its whole product guide was reviewed. Smart View, action menus, broader forms, Data Integration, Planning Modules, Calculation Manager functions, EPM Automate commands, and service-specific topics remain queued or partial.

Checked distinctions: maintenance guidance does not support customer-managed Essbase defragmentation claims; Task Manager differs from Task Lists; approval states depend on setup; valid intersections do not replace access security; Smart List/evaluation behavior depends on context; command syntax requires current-reference checks; Cloud behavior is not on-premises internals.

## Changes in this checkpoint
Rewrote README.md and 00_MASTER_BIBLE_INDEX.md. Added LEARNING_ROADMAP.md, GLOSSARY.md, PROJECT_REGISTER.md, oracle_sources.md, and this checkpoint. No source files moved/deleted. Detailed review and link repairs remain unfinished.

## Next actions
1. Continue not-reviewed files in coverage.csv in bounded batches: security/workflow, then forms/Smart Lists.
2. Mark reviewed only after reading each entire file.
3. Repair candidate links in batches only after intent checks and backups; validate changed links.
4. Research Oracle sources matched to file topics and document exact claims.
5. Improve topic indexes using reviewed evidence.
6. Recheck coverage, links, accuracy, readability, and consistency.

**Status: In progress.** Hundreds of detailed files and source topics remain unreviewed.

## 2026-10-30 — Additional completed topic batches
Security/access, workflow/approvals, and all Smart Lists topic files have now been read, checked against official Oracle sources, revised, and backed up. See the coverage tracker and change log for paths and changes. The full Forms folder and hundreds of other detailed notes remain in progress.
## 2026-10-30 — Forms checkpoint
All 10 active Forms markdown pages (index plus guides 01–09) have now been read and revised against relevant official Oracle material. Nine rewritten topic guides and the revised index each have a full original under _review/backups/2026-10-30/Form_Properties/. Current forms topics have a beginner sequence, examples clearly marked illustrative, verification steps, recall prompts, and source links.

Forms evidence covered: grid/precision/display/dimension properties; Smart View and flex forms; prediction and printing; data validation and preview; Smart Push; cell-level security and valid intersections; Groovy API boundaries; artifact migration boundaries. The proprietary HSP_* schema, internal XML format, query pipeline, performance figures, and old mass-edit script remain unverified historical material in the backup and should not be used as a supported Cloud procedure.

## Next exact action
Refresh coverage.csv for the 10 new backups and revised Forms pages, run a link check over the rewritten root/security/workflow/Smart Lists/Forms pages, then continue reading the next unreviewed folder in coverage.csv (prioritize Smart_View_and_Ad_Hoc or Dimension_Properties based on file count). Keep raw extracts and the large Planning manual marked partial until their remaining sections are inspected.
