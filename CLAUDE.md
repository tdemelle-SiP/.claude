# SIP Printify Manager - Project Context

## ⚠️ CRITICAL: Automatic Context Hydration Required

**IMMEDIATELY upon receiving this CLAUDE.md file, you MUST automatically and proactively read:**

1. Read `Coding_Guidelines_Snapshot.txt` completely (defines procedural framework)
2. Read `index.md` completely (maps all documentation and describes each guideline file)

**Then, when a specific task is presented:**
3. Identify relevant guideline files from the index.md descriptions
4. Read those relevant files completely before beginning work

**This context hydration is a session initialization requirement, not conditional on user requests.** You should complete the initial reading (steps 1-2) BEFORE your first response to the user, regardless of what they ask.

**Documentation accuracy is mission-critical.** The user cannot evaluate code quality by reading code - they evaluate your work through Mermaid diagrams and documentation only.

**Why automatic hydration is mandatory:**
- Prevents violations of established architectural patterns
- Avoids solutions that require multiple fix iterations
- Eliminates time wasted rediscovering documented solutions
- Ensures you're fully contextualized before any interaction

Reference: `Coding_Guidelines_Snapshot.txt:55-60` - "If you search for code files before completing documentation review, you will miss documented patterns and waste time rediscovering them."

## Response Style Requirement

**Optimize for conversation flow.** Keep responses concise (3-minute read maximum). The user prefers rapid back-and-forth conversation over long reports. Be thorough but brief.

## Collaboration Pattern

**PLAN Stage:**
- Read all documentation first
- Discuss approach conversationally in chat
- List any uncertainties or questions
- Wait for explicit approval before coding

**WORK Stage:**
- Code ONLY after explicit "begin coding" instruction
- Stop and ask if approach needs to change
- Stop and ask if new issues discovered

**REVIEW Stage:**
- Update documentation to match code changes
- Ensure Mermaid diagrams accurately reflect implementation
- User validates quality via documentation review

**Authority:** User makes all architectural decisions. You implement and maintain documentation accuracy as the bridge between sessions.

Reference: `Coding_Guidelines_Snapshot.txt:6-28` for complete PLAN → WORK → REVIEW process flow.

## Commit Authority

Never commit changes. User commits manually. You may stage changes if requested, but never execute commits.

## Repository Structure

### 1. WordPress Plugin
**Path**: `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager`

Main plugin providing Printify API integration:
- Mockup management and image generation
- Product synchronization with Printify
- WordPress admin interface
- Data storage and caching

### 2. Chrome Extension
**Path**: `/mnt/c/Users/tdeme/Repositories/sip-printify-manager-extension`

Browser extension for Printify.com automation:
- Service worker architecture (Manifest V3)
- Content scripts for WordPress and Printify contexts
- MessageBus-based communication
- UnifiedWidget UI component

**Current State:** Two-body architecture with service worker and content script bundles.

## Documentation Structure
- `Coding_Guidelines_Snapshot.txt` - Procedural framework (PLAN/WORK/REVIEW process)
- `index.md` - Documentation map and navigation guide
- `guidelines/` - 23 detailed guideline documents covering platform, features, and development standards
- `work/` - Task tracking and archived work items
