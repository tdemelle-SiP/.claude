# WIP File Lifecycle Standardization

## Current State

The WIP file is checked multiple times in the execution flow:

1. `sip_load_creation_template_wip_for_table()` - Checks for any WIP files
2. `sip_check_and_load_template_wip()` - Checks again and creates if needed
3. File is read multiple times instead of passing data

## WIP File Lifecycle

### Purpose
- A WIP (Work In Progress) file represents the current state of the product creation table
- Only one WIP file exists at a time (single active template)
- Created by copying a template file with `_wip.json` suffix

### Lifecycle Stages

1. **Check**: Determine if a WIP file exists
2. **Create**: Copy template to create new WIP if needed  
3. **Load**: Read WIP file contents
4. **Update**: Modify WIP file as user makes changes
5. **Clear**: Delete WIP file when done

## Recommendation

### Principle: Check Once, Pass Data

**Standard**: WIP file operations should follow a clear ownership pattern where data is loaded once and passed through the execution flow.

### Implementation:

1. **Consolidate Loading**:
   - `sip_check_and_load_template_wip()` should be the single entry point
   - It checks, creates if needed, and loads data in one operation
   - Returns complete data structure to avoid repeated file reads

2. **Remove Redundant Function**:
   - `sip_load_creation_template_wip_for_table()` functionality should be integrated into `sip_check_and_load_template_wip()`
   - Or make it a simple wrapper that calls the main function

3. **Data Flow**:
   ```
   Request → sip_check_and_load_template_wip() → {
     - Check if WIP exists for requested template
     - If not, create from template
     - Load and return data
     - Update referenced images
   } → Response with complete data
   ```

### Benefits:
- Single file read operation
- Clear ownership of WIP file operations
- Reduced file system access
- Simpler error handling

### Code Structure:
```php
function sip_check_and_load_template_wip($template_name = null) {
    // 1. Determine which WIP to load (existing or create new)
    // 2. Load/create in single operation
    // 3. Return complete data structure
    // 4. Let calling code handle the response
}
```