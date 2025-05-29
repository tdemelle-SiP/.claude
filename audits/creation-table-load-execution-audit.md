# Load Into Creation Table Execution Audit

## Purpose
Trace the complete execution path of the "Load Into Creation Table" action with no assumptions, referencing exact file locations and line numbers.

## Execution Trace

1. User selects option "Load Into Creation Table" (dashboard-html.php:184)
2. Form submission triggers preventDefault (template-actions.js:39)
3. Calls handleTemplateActionFormSubmit() (template-actions.js:42)
4. Gets action value "check_and_load_template_wip" (template-actions.js:206)
5. Gets selected rows from DataTable (template-actions.js:212)
6. Checks if rows selected (template-actions.js:215)
7. Extracts templateTitle from selectedRows[0] (template-actions.js:223)
8. Extracts templateFilename from selectedRows[0] (template-actions.js:224)
9. Removes .json extension from filename (template-actions.js:229)
10. Creates formData using createFormData() (template-actions.js:232)
11. Creates new FormData object (utilities.js:216)
12. Appends 'action' with config.ajaxAction (utilities.js:217)
13. Appends 'plugin' parameter (utilities.js:218)
14. Appends 'action_type' parameter (utilities.js:219)
15. Appends action_type value (utilities.js:220)
16. Appends 'nonce' from sipCoreAjax.nonce (utilities.js:223)
17. Returns FormData object (utilities.js:225)
18. Appends 'template_title' to formData (template-actions.js:233)
19. Calls handleAjaxAction() (template-actions.js:236)
20. Shows spinner if enabled (ajax.js:63)
21. Validates formData is FormData object (ajax.js:67)
22. Gets action from formData (ajax.js:73)
23. Gets plugin from formData (ajax.js:74)
24. Gets action_type from formData (ajax.js:75)
25. Validates action equals 'sip_handle_ajax_request' (ajax.js:77)
26. Validates plugin matches parameter (ajax.js:82)
27. Creates Promise for AJAX request (ajax.js:88)
28. Makes jQuery AJAX POST request (ajax.js:89)
29. Server receives request at 'sip_handle_ajax_request' (ajax-handler.php:52)
30. Gets plugin parameter from POST (ajax-handler.php:54)
31. Gets action_type parameter from POST (ajax-handler.php:55)
32. Verifies nonce security (ajax-handler.php:59)
33. Checks if plugin is in registered list (ajax-handler.php:76)
34. Triggers 'sip_plugin_handle_action' hook (ajax-handler.php:78)
35. Calls sip_printify_route_action() (printify-ajax-shell.php:15)
36. Checks plugin_id equals 'sip-printify-manager' (printify-ajax-shell.php:27)
37. Switches on action_type 'creation_setup_action' (printify-ajax-shell.php:30)
38. Calls sip_handle_creation_setup_action() (printify-ajax-shell.php:44)
39. Gets creation_setup_action from POST (creation-table-setup-functions.php:103)
40. Switches to 'check_and_load_template_wip' case (creation-table-setup-functions.php:106)
41. Calls sip_check_and_load_template_wip() (creation-table-setup-functions.php:107)
42. Gets template_name from POST['template_title'] (creation-table-setup-functions.php:17)
43. Calls sip_load_creation_template_wip_for_table() (creation-table-setup-functions.php:25)
44. Calls sip_plugin_storage()->get_folder_path() (creation-table-functions.php:1439)
45. Gets WIP files with glob() pattern (creation-table-functions.php:1440)
46. Checks if WIP files exist (creation-table-functions.php:1443)
47. If no WIP exists, checks template_name (creation-table-setup-functions.php:28)
48. Calls sip_create_wip_file() with template_name (creation-table-setup-functions.php:32)
49. Strips .json extension from template_name (creation-table-setup-functions.php:197)
50. Gets template path using sip_plugin_storage() (creation-table-setup-functions.php:198)
51. Checks if template file exists (creation-table-setup-functions.php:200)
52. Gets WIP directory path (creation-table-setup-functions.php:208)
53. Creates WIP filename with _wip suffix (creation-table-setup-functions.php:209)
54. Copies template file to WIP path (creation-table-setup-functions.php:210)
55. Returns success with WIP path (creation-table-setup-functions.php:218)
56. Checks if wip_result['success'] is true (creation-table-setup-functions.php:34)
57. Creates creation_template_wip array (creation-table-setup-functions.php:36)
58. Checks if WIP file exists (creation-table-setup-functions.php:45)
59. Reads WIP file contents (creation-table-setup-functions.php:47)
60. Decodes JSON to creation_template_wip_data (creation-table-setup-functions.php:47)
    61. Calls sip_update_referenced_images() (creation-table-setup-functions.php:50)
62. Prepares response_data array (creation-table-setup-functions.php:55)
63. Sets creation_template_wip_data value (creation-table-setup-functions.php:56)
64. Sets creation_template_wip_name value (creation-table-setup-functions.php:57)
65. Sets template_file value (creation-table-setup-functions.php:58)
66. Calls SiP_AJAX_Response::success() (creation-table-setup-functions.php:61)
67. Creates response array structure (class-ajax-response.php:53)
68. Sets success to true (class-ajax-response.php:54)
69. Sets plugin to 'sip-printify-manager' (class-ajax-response.php:55)
70. Sets action_type to 'template_action' (class-ajax-response.php:56)
71. Sets action to 'check_and_load_template_wip' (class-ajax-response.php:57)
72. Sets message to 'Template WIP loaded successfully' (class-ajax-response.php:58)
73. Sets data with response_data array (class-ajax-response.php:59)
74. Sends JSON response with wp_send_json() (class-ajax-response.php:68)
75. Client receives AJAX response (ajax.js:98)
76. Hides spinner if shown (ajax.js:101)
77. Calls handleSuccessResponse() (ajax.js:109)
78. Validates response structure (ajax.js:163)
79. Gets routePlugin from response.plugin (ajax.js:174)
80. Gets routeActionType from response.action_type (ajax.js:175)
81. Creates handler key 'sip-printify-manager:template_action' (ajax.js:185)
82. Finds registered handler for key (ajax.js:189)
83. Calls template_action success handler (ajax.js:191)
84. Returns to template-actions handleSuccessResponse() (template-actions.js:339)
85. Checks response.success is true (template-actions.js:343)
86. Switches on response.action 'check_and_load_template_wip' (template-actions.js:349)
87. Enters check_and_load_template_wip case (template-actions.js:361)
88. Checks response.data exists (template-actions.js:364)
89. Checks setCreationTemplateWipData function exists (template-actions.js:371)
90. Calls setCreationTemplateWipData() (template-actions.js:372)
91. Checks if reloadCreationTable exists (template-actions.js:388)
    92. Calls reloadCreationTable() (template-actions.js:389)
93. Checks if updateImageTableStatus exists (template-actions.js:393)
    94. Calls updateImageTableStatus() (template-actions.js:394)
95. Checks if updateProductTableHighlights exists (template-actions.js:398)
    96. Calls updateProductTableHighlights() (template-actions.js:399)
97. Gets templateFilename from response data (template-actions.js:403)
    98. Calls highlightSelectedTemplate() (template-actions.js:404)
99. Calls deselectAllTemplateRows() (template-actions.js:414)
100. Checks if templateTable exists (template-actions.js:420)
101. Deselects all rows in table (template-actions.js:421)
102. Execution complete - template loaded into creation table

## Summary

The "Load Into Creation Table" action follows a complex cross-table execution path:

1. **UI Trigger**: User selects action in template table (dashboard-html.php)
2. **JavaScript Handling**: Form submission handled by template-actions.js
3. **AJAX Request**: Sent via SiP.Core.ajax with action_type 'creation_setup_action'
4. **PHP Routing**: 
   - Central handler routes to sip-printify-manager plugin
   - Plugin routes to creation_setup_action handler
   - Executes check_and_load_template_wip function
5. **WIP File Management**:
   - Checks for existing WIP file
   - Creates new WIP by copying template if needed
   - Loads WIP data and updates referenced images
6. **Cross-Table Response**:
   - PHP sends response with action_type 'template_action' (not 'creation_setup_action')
   - This routes the response back to template-actions.js handler
7. **UI Updates**:
   - Updates window.creationTemplateWipData
   - Stores data in localStorage
   - Reloads creation table
   - Updates image and product table highlights
   - Highlights selected template
   - Deselects all template rows

## Key Files Involved

- **/views/dashboard-html.php** - UI dropdown
- **/assets/js/modules/template-actions.js** - Template table actions
- **/assets/js/core/ajax.js** (sip-plugins-core) - AJAX handling
- **/includes/ajax-handler.php** (sip-plugins-core) - Central AJAX router
- **/includes/printify-ajax-shell.php** - Plugin-specific router
- **/includes/creation-table-setup-functions.php** - WIP file operations
- **/includes/creation-table-functions.php** - Template loading functions
- **/includes/class-ajax-response.php** (sip-plugins-core) - Response formatting
- **/assets/js/modules/creation-table-setup-actions.js** - Creation table updates