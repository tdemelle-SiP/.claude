# Claude Documentation Guidelines

## Purpose of This Folder

This `.claude` folder contains **only information that is not easily deducible from the code itself**. It serves as a high-level orientation map for both human developers and AI assistants working with this codebase.

## Documentation Principles

1. **Minimize Redundancy**: Do not duplicate what is clear from reading the code
2. **Focus on Context**: Capture architectural decisions, rationales, and non-obvious patterns
3. **Maintain Accuracy**: Update these documents when fundamental architecture changes
4. **Preserve Tokens**: Keep documentation concise to preserve context tokens for code analysis

## Document Structure

- **project-overview.md**: The primary document containing consolidated high-level information
- Other specialized documents may be added when necessary for specific domains or components

## When To Update

Update this documentation when:
- Making architectural changes that affect multiple components
- Establishing new coding patterns or conventions
- Changing development environment requirements
- Refactoring that impacts the overall system design

Do NOT update for:
- Routine code changes
- Bug fixes that don't affect architecture
- Changes to implementation details that don't affect the overall structure