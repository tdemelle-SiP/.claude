# SiP Code Standards

## System Setup

- **Operating System**: Windows 11 with WSL2 (Linux 5.15.167.4)
- **Host Machine**: Odin
- **Dev Environment**: Local by Flywheel (WordPress local development)
- **Code Editor**: Visual Studio Code with Claude integration

## Project Location

- **Windows Path**: `C:\Users\tdeme\Local Sites\faux-stained-glass-panes\app\public\wp-content\plugins\sip-plugins-core`
- **WSL Path**: `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-plugins-core`

## Working Style Expectations

### Save Me Time and Effort
- Keep the flow quick, conversational and focused. Responses should take less than a minute for the user to read and understand. avoid prefaces and summaries
-Do not ask me to do things that you can do yourself
	-Do not aske me to:
		-ensure
		-verify
		-confirm
		-check
### Work Collaboratively
- Always discuss proposed solutions before implementing them
- Use the `/mnt/c/users/tdeme/Documents/VSCode_images_Repo/` folder for screenshots

### Code Smart
- Never act to alter code based on speculation. Always verify assumptions by looking at the logic and implementation of the actual code before making code changes
- Take a step back to ensure that you are fixing core issues and not symptoms.  Examine code issues through the lens of how you would solve the problem simply from the ground up with a fresh start.  Then reconsider what should be done to most simply, completely, robustly fix the issue.
- Do not overcomplicate.  Always favor simple solutions that build on the existing code as much as possible.  Do not add unnecessary complexity that will make it harder to test and iterate on exactly and only the issue at hand.  Make sure that the underlying structure of the code is simple clean and can be easily explained in layman's terms.  Do not add unnecessary layers of abstraction.  If there is not a clear benefit to adding a variable, do no add it.  Name things intuitively and clearly using the naming conventions established in the existing code.
- Never use write_to_file.  Always use find and replace and always create search patterns from the actual code before performing find-and-replace operations


## General Coding Principles

- Shared functionality and utilities from the sip-plugins-core plugin should be used when coding SiP plugins whenever possible.
- Error handling should be kept to an absolute minimum to reduce unnecessary complexity and to allow errors to be thrown to show where the code needs to be fixed
- Do not implement legacy code patterns; all code across all plugins should use any newly established code standard introduced through refactoring
- An experienced coder reviewing the code should consider the code to be:
- Not overly complex implementations
- Not over-engineering
- Not implemented with unnecessary abstraction

## File Structure

The established pattern in the existing code base for file hierarchy, naming conventions and file structure should be universally consistent in its implementation and extension. Refer to the  [SiP Plugin File Structure](./sip_plugin_file_structure.md) Document for details. 

### File Hierarchy

	#### JavaScript Files
	- Core functionality in `assets/js/core/` directory
	- Feature modules in `assets/js/modules/` directory
	- Third-party libraries in `assets/js/lib/` directory

	#### PHP Files
	- Include files in the `includes/` directory

	#### CSS Files
	- In the `assets/css/` directory
	- Component-specific styles in separate files
	- Global styles in main CSS file

### Naming conventions
- File names should be intuitive and specific following established patterns
- Class files should be prefixed with `class-`
- Main plugin PHP files should be named after the plugin

### File Structure

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