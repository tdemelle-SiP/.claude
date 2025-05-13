# SiP Plugin Suite AJAX Design Patterns

This document outlines the design patterns and approach to AJAX in the SiP Plugin Suite. Following these patterns ensures that AJAX handling is consistent, simple, and maintainable across all plugins in the suite.

## Core Principles

1. **Simplicity Over Complexity**: Always favor direct, simple solutions over complex ones. Avoid defensive programming when clear patterns and structures eliminate the need for it.

2. **Standardized Responses**: All AJAX responses should follow the standardized format provided by the `SiP_AJAX_Response` class. This ensures consistent handling on the client-side.

3. **Proper Routing**: Responses should always include identifying information so they can be routed to the correct handlers.

4. **Meaningful Errors**: Errors should be clear and helpful in identifying the issue, as they serve as diagnostic tools during development.

## Server-Side AJAX Patterns

### Using SiP_AJAX_Response Class

Always use the `SiP_AJAX_Response` class for sending AJAX responses. Never use direct `wp_send_json_*` functions.

```php
// CORRECT - Using standardized response
SiP_AJAX_Response::success(
    'sip-printify-manager',  // plugin identifier
    'product_action',        // action type
    'get_products',          // specific action
    $data,                   // data to send
    'Products loaded successfully'  // message
);

// INCORRECT - Direct WordPress JSON response
wp_send_json_success($data);  // Missing required routing fields
```

### Error Responses

Error responses should use the standardized format and include clear error messages:

```php
// CORRECT - Standardized error response with required fields
SiP_AJAX_Response::error(
    'sip-printify-manager',  // plugin identifier 
    'Invalid product ID',    // error message
    'validation_error',      // error code
    ['action_type' => 'product_action']  // Additional context
);

// INCORRECT - Direct error without proper routing information
wp_send_json_error('Invalid product ID');
```

## Client-Side AJAX Patterns

### Registering Success Handlers

Register success handlers using the core AJAX module:

```javascript
// CORRECT - Register handler with plugin and action_type
SiP.Core.ajax.registerSuccessHandler('sip-printify-manager', 'product_action', function(response) {
    // Process response
    console.log('Product action response:', response);
    return response;
});
```

### Creating FormData for Requests

Use the standardized method to create FormData with all required fields:

```javascript
// CORRECT - Create FormData with all required fields
const formData = SiP.Core.ajax.createStandardFormData(
    'sip-printify-manager',  // plugin 
    'product_action',        // action_type
    'get_products',          // specific action
    { 
        product_id: 123       // additional data
    }
);
```

## Common Issues & Solutions

### Missing Plugin/Action Type Fields

**Issue**: AJAX responses lacking `plugin` and `action_type` fields cause routing problems.

**Solution**: Always use `SiP_AJAX_Response` methods that include these fields.

### Cross-Plugin Response Handling

**Issue**: Responses from one plugin being processed by handlers from another plugin.

**Solution**: The core AJAX handler already validates responses against the expected plugin and action_type. Ensure all responses include these fields.

## Testing Approach

When debugging AJAX issues:

1. Check that responses include the `plugin` and `action_type` fields
2. Verify that these fields match the expected values in the registered handlers
3. Look for direct `wp_send_json_*` calls that should be converted to use `SiP_AJAX_Response`

## Remember

- Simple is better than complex
- Let errors guide you to the actual issues rather than hiding them with defensive code
- Maintainability comes from consistency in patterns and structures
- The existing framework already handles most edge cases properly when used correctly