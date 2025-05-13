# Effective Terminal and System Operations

When working with the SiP Plugin Suite in a Windows Subsystem for Linux (WSL) environment, follow these best practices for file system operations:

## File Path Handling

- Always double-quote file paths containing spaces: `ls "/mnt/c/Users/tdeme/Local Sites"`
- Use path verification before executing destructive commands: run `ls` to verify paths first
- Use incremental approaches: check parts of complex paths to identify where issues may occur
- Remember that WSL paths and Windows paths use different conventions and separators

## Tool Preferences

- Prefer using built-in Claude Code tools (`Read`, `LS`) over Bash commands when possible
- For file searches, use `Glob` and `Grep` tools instead of direct Bash commands
- When manipulating files and directories, prefer to use absolute paths

## Safety Procedures

- Always check if directories exist before attempting to create files in them
- For file operations that could fail in WSL, validate success with a follow-up command
- When modifying files, make a backup or verify you can revert changes if needed
- Use `find` and similar commands with extreme caution to avoid accidental recursion through system directories