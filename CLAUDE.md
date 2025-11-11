# SIP Printify Manager - Project Context

## ⚠️ CRITICAL: Documentation-First Development

**Documentation accuracy is mission-critical.** The user cannot evaluate code quality by reading code - they evaluate your work through Mermaid diagrams and documentation only.

**BEFORE taking ANY action, you MUST:**
1. Read `Coding_Guidelines_Snapshot.txt` completely (defines procedural framework)
2. Read `index.md` completely (maps all documentation)
3. Read ALL relevant guideline files completely (not skimmed)

**This is mandatory, not optional.** Failure to read documentation before acting causes:
- Violations of established architectural patterns
- Solutions that require multiple fix iterations
- Wasted time rediscovering solutions already documented

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

**Current State:** Uses refactored v1.2 architecture. All code under `refactored/` directory.

## Documentation Structure
- `Coding_Guidelines_Snapshot.txt` - Procedural framework (PLAN/WORK/REVIEW process)
- `index.md` - Documentation map and navigation guide
- `guidelines/` - 23 detailed guideline documents covering platform, features, and development standards
- `work/` - Task tracking and archived work items
