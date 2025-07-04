# Extension Documentation Update Task

## Quick Start
You need to update the SiP Printify Manager Extension documentation to align with the code and follow documentation guidelines.

**Primary Document to Update**: 
`/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/.claude/guidelines/sip-printify-manager-extension-widget.md`

**Code Location**: 
`/mnt/c/Users/tdeme/Repositories/sip-printify-manager-extension/`

## Recent Changes Made to Code
1. **Validation Consolidation**: All message validation now happens in the router (`widget-router.js`). The relay (`widget-relay.js`) only does security checks. This simplifies the architecture.

## Step-by-Step Tasks

### 1. DELETE These Sections (Violate "No Future/History" Rule)
- Lines 3-4: Version number and "Last Updated" date
- Lines 147-283: Entire "Distribution & Release Management" section  
- Lines 536-635: Chrome Web Store sections
- Any mentions of version numbers, roadmaps, or historical changes

### 2. SPLIT the Giant Diagram (Lines 195-452)
The "Corrected Implementation Diagram" is 255 lines. Split into these focused diagrams (each <50 lines):

**Diagram A: Message Flow**
- Show: WordPress → postMessage → Relay → Router → Handler → Response
- Include: Message format transformation

**Diagram B: Component Organization**  
- Show: WordPress Environment, Content Scripts, Background Scripts, External Systems
- Include: Which scripts belong where

**Diagram C: Storage & State**
- Show: Chrome Storage, Runtime State, onChange events
- Include: How UI updates via storage

**Diagram D: Error Recovery**
- Show: Pause/Resume flow (currently missing from diagrams)
- Include: Error detection → Pause → User Fix → Resume

### 3. ADD Missing Architectural Patterns

These exist in code but aren't in diagrams:

**Debug Level Sync**: Every WordPress message includes debug level. Extension auto-updates its debug settings.

**Pause/Resume System**: When errors occur (login required, 404), operations pause, user fixes issue, then resumes.

**Configuration Loading**: Extension can load config from `config.json` file.

### 4. CONSOLIDATE Duplicate Information
- Keep WordPress commands list in ONE place (section 13.2)
- Keep file structure in ONE place (section 6.1)
- Remove duplicate legends after diagrams

### 5. ADD Code Examples
These sections need <50 line code examples:
- Message Format Conversion (line 732) - show actual message transformation
- Tab Pairing System (line 1078) - show pairing creation/lookup
- Error Recovery System (line 1476) - show pause/resume implementation

### 6. FIX Section Numbering
Current: 2.1 appears after 2.2, 2.3, 2.4
Fix: Renumber sequentially

## Key Architecture Points (Must Be Clear in Docs)

1. **Central Hub Pattern**: ALL messages go through router - no exceptions
2. **Context Boundaries**: Web pages can't directly talk to background script
3. **Single Validation Point**: Router validates everything (recent change)
4. **Event-Driven UI**: Storage onChange events update UI automatically
5. **Elegant Simplicity**: No defensive code, direct solutions

## Guidelines to Follow

From `sip-documentation-guidelines.md`:
1. NO FUTURE OR HISTORY - Current state only
2. ARCHITECTURAL WHY - Explain design decisions  
3. EXAMPLES OVER EXPLANATIONS - Show working code
4. DIAGRAM BEFORE PROSE - Visual first
5. CODE LIMITS - <50 lines per example
6. SINGLE SOURCE OF TRUTH - No duplication
7. STRUCTURED HIERARCHY - General to specific
8. CONCISE HEADERS - Brief titles
9. ACTIVE VOICE - Direct language
10. CONSISTENT TERMINOLOGY - Same terms throughout

From `sip-documentation-mermaid-diagram-guidelines.md`:
- Show actual function names, not descriptions
- Every function in data flow must appear
- Keep diagrams focused and under 50 lines

## Success Checklist
- [ ] All version/date/history removed
- [ ] Giant diagram split into 4 focused diagrams
- [ ] Pause/Resume pattern added to diagrams
- [ ] Debug sync shown in diagrams
- [ ] All duplicate info consolidated
- [ ] Code examples added where missing
- [ ] Section numbers sequential
- [ ] Follows all 10 documentation rules

## Start Here
1. Open the main document
2. Delete the sections listed in Task 1
3. Split the diagram as described in Task 2
4. Continue through tasks sequentially

The goal: Clean, accurate documentation that matches the code and helps developers understand the elegant architecture.