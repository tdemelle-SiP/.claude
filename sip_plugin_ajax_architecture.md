# Core AJAX Architecture

The SiP Plugin Suite uses a centralized AJAX handling system that provides consistent behavior across all plugins.

## PHP Side

- **Central Router**: `ajax-handler.php` routes requests to the appropriate plugin based on the plugin parameter
- **Standardized Responses**: `SiP_AJAX_Response` class provides consistent response formatting
- **Plugin Handlers**: Each plugin has its own AJAX handlers registered via WordPress actions (e.g., `sip_printify_handle_action`)
- **Security**: Consistent nonce verification through a fixed nonce action

## JavaScript Side

- **Core Module**: `SiP.Core.ajax.js` provides centralized request handling
- **Request Method**: `handleAjaxAction()` sends requests with proper parameters
- **Response Handling**: `registerSuccessHandler()` registers callbacks for specific plugin/action combinations
- **Response Filtering**: Responses are filtered to ensure handlers only process their own plugin's responses
- **Spinner Management**: Spinner state is stored at the beginning of requests to prevent flashing during background polling

## Standardized Response Format

All AJAX responses use a consistent format with these fields:

- `success`: Boolean indicating success or failure
- `plugin`: The plugin identifier (e.g., 'sip-printify-manager')
- `action_type`: The type of action (e.g., 'product_action')
- `action`: The specific action (e.g., 'upload_product')
- `message`: Optional message text
- `data`: The response data payload

## Common Patterns

- **Action Dispatching**: Plugins use a dispatcher function to route to specific handlers based on the action type
- **Error Handling**: Error responses include an error code and message
- **Progress Tracking**: For long-running operations, standardized progress response format is available
- **DataTables Integration**: Special response format for DataTables pagination and filtering