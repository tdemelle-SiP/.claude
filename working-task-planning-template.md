# Action Logger Enhancement Task Plan

## Task Overview
Enhance the action logger to provide better visual hierarchy for operations, fix progress bar display, and make log messages more informative.

## Current State Analysis
### What Works
- Basic action logging functionality
- Terminal display shows messages
- Progress bar percentage updates

### What Needs Implementation
1. **Action Log Formatting**:
   - Add visual hierarchy for operation start/end
   - Use indentation for sub-operations
   - Add operation boundary markers (🔻 start, 🔺 end)

2. **Progress Bar Fix**:
   - Ensure fill percentage matches displayed percentage
   - Verify CSS width property is properly applied

3. **More Informative Messages**:
   - Add specific details to navigation messages
   - Include product names and counts in operations
   - Add connection details to test messages
   - Include error specifics

## Implementation Steps

### Step 1: Add Operation Tracking to ActionLogger
- Track when operations start/end
- Add operation stack for hierarchy
- Format logs with proper indentation

### Step 2: Fix Progress Bar Display
- Debug why fill percentage doesn't match
- Ensure inline style width is properly set
- Check for CSS conflicts

### Step 3: Enhance Log Messages
- Update navigation messages with tab details
- Add product info to mockup operations
- Include URL/endpoint in connection tests
- Add specific error details

## Technical Constraints
- Must maintain backward compatibility
- Cannot break existing log storage format
- Must work in both service worker and content scripts

## Success Criteria
- Operations show clear start/end boundaries
- Sub-operations are visually indented
- Progress bar fill matches percentage exactly
- Log messages contain actionable details
- No existing functionality is broken

## Questions
None - requirements are clear.

## Risks
- Modifying core logging system could affect all operations
- Need to ensure performance isn't impacted by additional tracking