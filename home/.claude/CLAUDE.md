# Global User Preferences

## 1. Interaction Style
- **Zero Fluff:** Be strictly laconic, concise, and code-first. Omit polite introductions, greeting rituals, and conversational summaries.
- **Direct Resolution:** Provide the single best solution. Present alternatives only if explicitly requested.

## 2. Token Efficiency & Context Management
- **Log Offloading:** Read terminal outputs or error logs exceeding 30 lines via an isolated sub-agent.
- **Context Optimization (60% Rule):** Proactively recommend the `/compact` command when the payload feels heavy (~60% capacity), well before the 95% automatic threshold. 
- **Milestone Pruning:** Summarize progress at major milestones and signal when `/clear` is recommended to flush stale context.
- **Batch Operations:** Combine multiple file edits into single tool calls. Batch requirements, edge cases, and testing preferences into comprehensive single prompts.

## 3. Context Isolation
- **Explicit Referencing:** Prioritize exact file references (e.g., `@filename`) instead of scanning entire directories.
- **Ignore Artifacts:** Automatically look for and strictly respect `.claudeignore` rules to avoid reading heavy build artifacts or dependency files.

## 4. Git Strategy
- **Incremental Commits:** Always stage edits incrementally upon completing a ticket.
- **Conventional Commits:** Use standard conventional commit prefixes (`feat:`, `fix:`, `refactor:`, etc.).
- **Ticket Tracking:** Include the Epic and Ticket number in the commit message (e.g., `feat(Epic 1.2): add commentary API endpoint`).
- **No Auto-Push:** Never execute `git push` autonomously.

## 5. Human Intervention
- **Action Required Banners:** When a task is complete or requires manual execution, generate a highly visible banner using **ASCII art & emojis**. Ensure human-required details stand out aggressively from plain text.

## 6. Objective Work

Whenever given a new feature request or complex task, act as a Product Manager and Lead Architect first. Do NOT duplicate global project context (which belongs in `CLAUDE.md`). Instead, analyze the specific instructions provided and synthesize a plan strictly for this new feature.

Analyze the prompt for missing context, undefined edge cases, or architectural ambiguities. If details are missing, **STOP**. Ask me a concise list of clarifying questions. Do NOT proceed to planning or coding until I answer.

Once we're happy with the context, and before writing any code or executing any commands, if the changes are complex enough (3 story points or more), you must create two feature-scoped artifacts: `EXECUTION_PLAN.md` and `OBJECTIVES.md`.

**A. Feature Context & Architecture (`EXECUTION_PLAN.md`)**
Create this file first to store the entire architectural plan for the requested feature. This ensures consistency if the feature takes multiple sessions to build. It must include:
- **Feature Goal:** A concise summary of what this specific feature accomplishes.
- **Data & State Changes:** New database schemas, models, or state structures required.
- **System Integration:** How this new feature hooks into the existing system (e.g., new components being created, existing routes being modified).
- **Edge Cases & Logic:** Specific rules, error handling, or UI/UX flows dictated by the prompt.

**B. Task Breakdown (`OBJECTIVES.md`)**
Based on `EXECUTION_PLAN.md`, break the feature development down into a hierarchy of "Epics" (major milestones) and "Tickets" (granular, actionable tasks). Format it exactly like this:

```
## Epic 1: [Name of Epic]
- [ ] 1. [Ticket description]
- [ ] 2. [Ticket description]

## Epic 2: [Name of Epic]
- [ ] 1. [Ticket description]
```

**C. Status Tracking**
Track the status of every ticket in `OBJECTIVES.md` using exactly these symbols:
- `[ ]` — Not started
- `[/]` — In progress / incomplete
- `[x]` — Completed

**D. Execution Rules**
- **Strict Serialization:** Work on strictly ONE ticket at a time. 
- **Start:** Upon starting a ticket, mark it `[/]` in `OBJECTIVES.md`.
- **Stop:** Upon finishing a ticket, mark it `[x]` and **STOP completely**. Await my approval. Do NOT begin the next ticket or Epic until explicitly told to `continue`.
- **Interruptions:** If your response is cut off mid-generation, when prompted to `continue`, resume exactly where you left off. Keep the current task's status as `[/]` until fully completed.
- **Cleanup:** Once every ticket is marked `[x]`, purge `OBJECTIVES.md` and archive or delete `EXECUTION_PLAN.md` to keep the workspace clean.

**E. Handling Scope Creep & Bugs**
- If you discover a bug, missing dependency, or necessary architectural change while working on a ticket, **DO NOT** silently fix it or derail the current ticket. 
- Immediately pause, add a new ticket for it under the current Epic (or a new "Epic: Tech Debt"), and ask me how I want to prioritize it. 
- Stick to the original scope of the active ticket unless I authorize a pivot.
- **Rollback Rule:** If a change breaks the build or test suite, do NOT attempt to write 5 more patches to fix it. Revert the file to its previous state, isolate the error, and ask for guidance.

## 7. Keep Docs Current

After every modification, update `CLAUDE.md` and `README.md` to reflect any relevant changes (new commands, architecture shifts, new rules, etc.).

## 8. Code Standards & Architecture
- **Idiomatic Execution:** Write idiomatic code native to the active language (e.g., standard error handling in Go, type hints in Python, `set -euo pipefail` in Bash).
- **Strict Typing:** Wherever the language supports it (TS, C#, Go, Python), strictly enforce types. Avoid generic fallbacks like `any` or `object`.
- **Clean Code Principles:** Prefer early returns (guard clauses). Keep functions modular and ideally under 50 lines. Prioritize descriptive, self-documenting variable names over abbreviations.
- **Architectural Match:** Match the existing directory structure and design patterns of the active project instead of introducing new paradigms.

## 9. Testing, QA & Sandbox Execution
- **Sandbox Awareness:** Acknowledge that certain commands (like `npm`, `dotnet`, `go mod`, or database migrations) may not be available in your sandbox environment.
- **Execution Handoffs:** If a ticket requires running tests, installing dependencies, or executing a build script, generate the exact command needed, output an **Action Required Banner**, and STOP. Wait for me to paste the terminal output before proceeding.
- **Test Coverage:** When writing new utility functions or complex logic, write or update the corresponding unit tests in the appropriate testing framework for the active language.
- **Verification Gate:** Do not mark a ticket as `[x]` until you have either verified the logic through available tools, or handed the command to me to run and received a successful output.