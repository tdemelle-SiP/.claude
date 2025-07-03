# AJAX Architecture Diagram Draft

## Mermaid Diagram for sip-plugin-ajax.md

This diagram should be placed at the beginning of the AJAX documentation, right after the Overview section.

```mermaid
sequenceDiagram
    participant U as User Action
    participant JS as JavaScript Module
    participant Core as SiP.Core.ajax
    participant WP as admin-ajax.php
    participant CH as Core Handler<br/>(sip_core_handle_ajax)
    participant PH as Plugin Handler<br/>(sip_{plugin}_handle_{type})
    participant AH as Action Handler<br/>(specific function)
    participant DB as Database/API
    
    U->>JS: Click/Submit
    JS->>JS: createFormData()<br/>plugin, type, action
    JS->>Core: handleAjaxAction()
    Core->>WP: POST Request
    WP->>CH: wp_ajax_sip_core_ajax
    
    Note over CH: Level 1: Core Routing
    CH->>CH: Validate nonce
    CH->>CH: Check plugin exists
    CH->>PH: do_action()<br/>sip_{plugin}_handle_{type}
    
    Note over PH: Level 2: Plugin Routing
    PH->>PH: Check capabilities
    PH->>PH: Route by $_POST[{type}_action]
    PH->>AH: Call specific handler
    
    Note over AH: Level 3: Action Execution
    AH->>DB: Perform operation
    DB-->>AH: Result
    AH->>AH: Format response
    AH-->>PH: Return data
    
    PH->>PH: SiP_AJAX_Response
    PH-->>WP: JSON Response
    WP-->>Core: Response
    Core->>Core: Route by action_type
    Core-->>JS: Success/Error callback
    JS->>U: Update UI
```

## Key Points to Emphasize

1. **Three-Level Architecture**:
   - Core Handler: Security and plugin routing
   - Plugin Handler: Type-based routing
   - Action Handler: Specific operation

2. **Parameter Naming Convention**:
   - `plugin_id` → routes to plugin
   - `action_type` → routes to handler within plugin
   - `{action_type}_action` → specific action to perform

3. **Response Routing**:
   - PHP sets `action_type` in response
   - JavaScript routes to appropriate success handler
   - Enables cross-module operations

## Example Flow Annotation

Add this example below the diagram:

```
Example: Delete Template Action

1. User clicks "Delete Template" button
2. JS creates FormData:
   - plugin_id: 'printify-manager'
   - action_type: 'template'
   - template_action: 'delete'
3. Core routes to: sip_printify-manager_handle_template
4. Plugin handler checks for 'delete' in $_POST['template_action']
5. Calls delete_template() function
6. Returns success with action_type: 'template_deleted'
7. JS routes to templateDeleted() handler
```