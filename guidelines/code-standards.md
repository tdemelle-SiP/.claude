# SiP Code Standards

## General Principles

- Code should be adherent to best standard practices
- Code should be clear, intuitive, clean, simple, well-structured
- Avoid overly complex implementations
- Avoid over-engineering
- Avoid unnecessary abstraction
- Avoid overly defensive coding patterns

## Approach to Code Maintenance

- Implement only one method for each functionality (no legacy support patterns)
- When refactoring, update legacy code to follow the new implementation patterns
- Keep error handling minimal; don't hide symptoms of structural issues
- Throw errors for core issues rather than patching symptoms
- Never make changes based on speculation - always verify with code analysis
- Always check actual code before performing find-and-replace operations

## Specific Standards

### Legacy Code

- There should not be any functionality supporting legacy code; there should be only one method for functionality
- If code is updated and refactored, legacy code should be updated to follow the patterns and protocols of the updated implementation

### Error Handling

- Error handling should be kept to a minimum
- Error handling should never address or hide symptoms of structural issues
- These types of issues should throw errors and the core issue should be addressed at its source

### Development Approach

- Never propose or make changes based on speculation
- If your analysis contains phrases like "the issue might be" or "it's likely that", go back and look at the code
- Only take action with definitively established data

### Code Editing

- Never perform find and replace from memory
- Always check the actual code so that find strings are 100% accurate
- Do not rely on write_to_file if find strings don't work
- Check the code and retry with accurate strings

## File Structure

### PHP Files

- Class files should be prefixed with `class-`
- Utility files should have descriptive names
- Include files in the `includes/` directory
- Main plugin files should be named after the plugin

### CSS Files

- Component-specific styles in separate files
- Global styles in main CSS file
- Use consistent naming scheme for all files

### JavaScript Files

- Core functionality in `core/` directory
- Feature modules in `modules/` directory
- Third-party libraries in `lib/` directory

## Naming Conventions

### PHP

- Classes: `SiP_ClassName`
- Functions: `sip_function_name()`
- Constants: `SIP_CONSTANT_NAME`

### JavaScript

- Namespaces: `SiP.ModuleName`
- Functions: `camelCase()`
- Constants: `UPPER_CASE`

### CSS

- Classes: `sip-component-name`
- IDs: `sip-specific-element`