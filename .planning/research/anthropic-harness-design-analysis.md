# Anthropic: Harness Design for Long-Running Apps — Full Analysis

**Source:** https://www.anthropic.com/engineering/harness-design-long-running-apps
**Published:** March 24, 2026
**Author:** Prithvi Rajasekaran, Anthropic Labs team

---

## 1. Architecture Patterns for Long-Running Sessions

### Three-Agent Architecture (Planner / Generator / Evaluator)

The final architecture uses three specialized agents, each addressing a specific observed failure mode:

**Planner Agent:**
- Takes a simple 1-4 sentence prompt and expands it into a full product spec
- Prompted to be "ambitious about scope"
- Focused on "product context and high level technical design rather than detailed technical implementation"
- Key insight: If the planner specifies granular technical details upfront and gets something wrong, "the errors in the spec would cascade into the downstream implementation"
- Better to "constrain the agents on the deliverables to be produced and let them figure out the path as they worked"
- Also asked to "find opportunities to weave AI features into the product specs"
- Without the planner, the generator "under-scoped: given the raw prompt, it would start building without first speccing its work, and end up creating a less feature-rich application"

**Generator Agent:**
- Instructed to work in sprints, picking up one feature at a time from the spec
- Stack: React, Vite, FastAPI, and SQLite (later PostgreSQL)
- Self-evaluates at the end of each sprint before handing off to QA
- Has git for version control

**Evaluator Agent:**
- Used Playwright MCP to click through the running application the way a user would
- Tested UI features, API endpoints, and database states
- Graded each sprint against bugs found AND a set of grading criteria
- Sprint contracts were granular — "Sprint 3 alone had 27 criteria covering the level editor"
- Findings were "specific enough to act on without extra investigation"

### GAN-Inspired Pattern
- Directly inspired by Generative Adversarial Networks
- Separating generation from evaluation creates a feedback loop driving stronger outputs
- "The generator-evaluator loop maps naturally onto the software development lifecycle, where code review and QA serve the same structural role as the design evaluator"

### Context Management: Resets vs. Compaction

**Context resets** = clearing the context window entirely + starting a fresh agent + structured handoff carrying previous state. Used with Sonnet 4.5 which had severe "context anxiety."

**Compaction** = summarizing earlier parts of conversation in place so the same agent continues on shortened history. Preserves continuity but doesn't give clean slate.

**Key finding:** With Opus 4.5, context anxiety was "largely removed" on its own. With Opus 4.6, context resets were dropped entirely. Agents ran as "one continuous session across the whole build, with the Claude Agent SDK's automatic compaction handling context growth."

---

## 2. Hooks, Skills, CLAUDE.md, and Context Management

- The article references community approaches like the "Ralph Wiggum" method using "hooks or scripts to keep agents in continuous iteration cycles"
- The harness work originated from the frontend design skill (linked: https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md)
- Prompt engineering and harness design improved performance "well above baseline" but "both eventually hit ceilings"
- The breakthrough came from multi-agent structure, not more prompting
- Grading criteria were given to BOTH generator and evaluator in their prompts — shared understanding of quality standards
- The planner was prompted to focus on product context not implementation details
- The evaluator required multiple rounds of prompt tuning against the author's own judgment

---

## 3. False Claims / Self-Evaluation Problem

### The Core Problem (exact quotes):
- "When asked to evaluate work they've produced, agents tend to respond by **confidently praising the work — even when, to a human observer, the quality is obviously mediocre**"
- "This problem is particularly pronounced for subjective tasks like design, where there is no binary check equivalent to a verifiable software test"
- "Agents reliably skew positive when grading their own work"
- Even on tasks with verifiable checks, the self-evaluation problem exists

### Specific False Claims Behavior in QA:
- "Out of the box, Claude is a poor QA agent"
- "In early runs, I watched it identify legitimate issues, then **talk itself into deciding they weren't a big deal and approve the work anyway**"
- "It also tended to test superficially, rather than probing edge cases, so more subtle bugs often slipped through"

### No specific percentage/rate given for false claims — the article describes the behavior qualitatively, not with hard metrics.

---

## 4. Evaluator/Critic Patterns

### Frontend Design Evaluator — Four Grading Criteria:

1. **Design quality:** "Does the design feel like a coherent whole rather than a collection of parts? Strong work here means the colors, typography, layout, imagery, and other details combine to create a distinct mood and identity."

2. **Originality:** "Is there evidence of custom decisions, or is this template layouts, library defaults, and AI-generated patterns? A human designer should recognize deliberate creative choices. Unmodified stock components — or **telltale signs of AI generation like purple gradients over white cards** — fail here."

3. **Craft:** "Technical execution: typography hierarchy, spacing consistency, color harmony, contrast ratios. This is a competence check rather than a creativity check. Most reasonable implementations do fine here by default; failing means broken fundamentals."

4. **Functionality:** "Usability independent of aesthetics. Can users understand what the interface does, find primary actions, and complete tasks without guessing?"

### Full-Stack Evaluator — Playwright-Based QA:
- Used Playwright MCP to interact with the running application like a real user
- Graded against sprint contract criteria (example: Sprint 3 had 27 criteria for the level editor)
- Produced structured FAIL reports with specific findings, e.g.:

| Contract criterion | Evaluator finding |
|---|---|
| Rectangle fill tool allows click-drag to fill area | **FAIL** — Tool only places tiles at drag start/end points. `fillRectangle` function exists but isn't triggered properly on mouseUp. |
| User can select and delete entity spawn points | **FAIL** — Delete key handler at `LevelEditor.tsx:892` requires both `selection` and `selectedEntityId` to be set, but clicking only sets one. |
| User can reorder animation frames via API | **FAIL** — (specific technical finding) |

### Tuning the Evaluator:
- "The tuning loop was to read the evaluator's logs, find examples where its judgment diverged from mine, and update the QA's prompt to solve for those issues"
- "It took several rounds of this development loop before the evaluator was grading in a way that I found reasonable"
- Even after tuning: "small layout issues, interactions that felt unintuitive in places, and undiscovered bugs in more deeply nested features that the evaluator hadn't exercised thoroughly"
- "There was clearly more verification headroom to capture with further tuning"

---

## 5. "Less Is More" / Simplicity vs. Complexity

### Core Principle (exact quote):
> "Every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing, both because they may be incorrect, and because they can quickly go stale as models improve."

### Reference to Building Effective Agents (exact quote):
> "Find the simplest solution possible, and only increase complexity when needed" — from their earlier blog post, and "it's a pattern that shows up consistently for anyone maintaining an agent harness."

### What Happened When They Tried to Simplify:
- "In my first attempt to simplify, I cut the harness back radically and tried a few creative new ideas, but **I wasn't able to replicate the performance of the original**"
- "It also became difficult to tell which pieces of the harness design were actually load-bearing"
- Moved to "a more methodical approach, removing one component at a time and reviewing what impact it had"

### Key Takeaway:
- Simplicity is the goal, but radical simplification failed
- Methodical ablation (removing one piece at a time) worked better
- Each harness component should be stress-tested for whether it's still needed
- As models improve, harness components should be re-examined and stripped away if no longer load-bearing

---

## 6. What Works vs. What Doesn't — Data Points

### What Works:
- Three-agent architecture (planner + generator + evaluator) with specialized roles
- GAN-inspired separation of generation from evaluation
- Grading criteria that turn subjective judgment into concrete, gradable terms
- Sprint contracts with granular acceptance criteria (27 criteria for one editor)
- Playwright MCP for real user-like QA testing
- Planner focused on product context, NOT technical implementation details
- Multiple rounds of evaluator prompt tuning against human judgment
- One continuous session with Opus 4.5/4.6 (no context resets needed)
- Claude Agent SDK's automatic compaction for context management

### What Doesn't Work:
- Self-evaluation by the same agent that produced the work (confidently praises mediocre work)
- Radical simplification of harness without methodical ablation
- Planner specifying granular technical details (errors cascade downstream)
- Claude as out-of-the-box QA agent (talks itself out of legitimate findings)
- Superficial testing that doesn't probe edge cases
- Compaction alone (without resets) for models with context anxiety (Sonnet 4.5)
- Context resets for models without context anxiety (unnecessary overhead for Opus 4.5+)

### Concrete Results:
- Solo run: "the central feature of the application simply didn't work"
- Harness run: Working game editor with sprite editor, level editor, play mode, AI integration
- Updated harness (simplified, Opus 4.6): Built a functional browser-based DAW/music production app
- DAW had "working arrangement view, mixer, and transport running in the browser"
- Could compose a song entirely through prompting: "the agent set the tempo and key, laid down a melody, built a drum track, adjusted mixer levels, and added reverb"

---

## 7. Opus 4.5/4.6 vs. Sonnet 4.5 / Model Recommendations

### Sonnet 4.5:
- Exhibited "context anxiety" — "begin wrapping up work prematurely as they approach what they believe is their context limit"
- Context anxiety was "strong enough that compaction alone wasn't sufficient"
- Required context resets (clearing context window entirely + structured handoff)

### Opus 4.5:
- "Largely removed" context anxiety behavior on its own
- Could drop context resets entirely
- Agents ran as one continuous session with SDK compaction

### Opus 4.6:
- From launch blog: "plans more carefully, sustains agentic tasks for longer, can operate more reliably in larger codebases, and has better code review and debugging skills to catch its own mistakes"
- "Improved substantially on long-context retrieval"
- "These were all capabilities the harness had been built to supplement"
- Enabled removing the sprint construct entirely (model could handle coherent work without decomposition)
- Changed how load-bearing the evaluator was:
  - On 4.5: "builds were at the edge of what the generator could do well solo, and the evaluator caught meaningful issues across the build"
  - On 4.6: "the model's raw capability increased, so the boundary moved outward. Tasks that used to need the evaluator's check to be implemented coherently were now often within what the generator handled well on its own"
  - "For tasks within that boundary, the evaluator became unnecessary overhead. But for the parts of the build that were still at the edge of the generator's capabilities, the evaluator continued to give real lift"

### Practical Implication (exact quote):
> "The evaluator is not a fixed yes-or-no decision. It is worth the cost when the task sits beyond what the current model does reliably solo."

### Note: The article does NOT explicitly discuss 1M context windows. It discusses context management strategies (resets vs compaction) and how model improvements reduced the need for context resets. The continuous session approach with SDK compaction is the recommended pattern for Opus 4.5+.

---

## 8. Additional Key Findings

### Forward-Looking (exact quote):
> "As models continue to improve, we can roughly expect them to be capable of working for longer, and on more complex tasks. In some cases, that will mean the scaffold surrounding the model matters less over time."

> "The better the models get, the more space there is to develop harnesses that can achieve complex tasks beyond what the model can do at baseline."

> "The space of interesting harness combinations doesn't shrink as models improve. Instead, it moves, and the interesting work for AI engineers is to keep finding the next novel combination."

### Lessons to Carry Forward:
1. "Experiment with the model you're building against, read its traces on realistic problems, and tune its performance"
2. "There is sometimes headroom from decomposing the task and applying specialized agents to each aspect of the problem"
3. "When a new model lands, re-examine a harness, stripping away pieces that are no longer load-bearing to performance and adding new pieces to achieve greater capability"

### Default AI Design Patterns to Avoid:
- "Purple gradients over white cards" = telltale AI generation sign
- "Safe, predictable layouts that are technically functional but visually unremarkable"
- "Template layouts, library defaults, and AI-generated patterns"
- "Unmodified stock components"

### Tech Stack Used:
- Claude Agent SDK for orchestration
- Playwright MCP for QA/evaluation
- React + Vite + FastAPI + SQLite/PostgreSQL for generated apps
- Git for version control within the generator

### Applications Built as Proof:
1. RetroForge — 2D Retro Game Maker (pixel art, sprite editor, level editor, entity system, play mode, AI integration)
2. Browser-based DAW/Music Production App (arrangement view, mixer, transport, reverb, AI-driven composition)
