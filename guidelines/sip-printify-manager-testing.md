# SiP Printify Manager Testing Guide

## Overview

This guide documents testing procedures for the SiP Printify Manager plugin, including API behavior testing and other experimental features.

## Printify API Field Testing

### Purpose

The Printify API documentation is incomplete. This testing system helps discover:
- Which undocumented fields Printify accepts during product creation
- How Printify modifies or validates field values
- What causes upload errors
- The difference between what we send and what Printify stores

### Architecture

The testing system is built into the product upload process with a simple toggle:

```php
// In sip_upload_child_product_to_printify() around line 1177
$enable_test_injection = false;  // Set to true to enable testing
```

When enabled, test data from a JSON file is injected into the product creation payload just before the API call.

### Test Data Location

- **Input**: `/wp-content/plugins/sip-printify-manager/work/test_product_images_views_data.json`
- **Output**: `/wp-content/uploads/sip-printify-manager/templates/wip/api_json_test_*.json`

### Running a Test

#### 1. Prepare Test Data

Create or modify the test data file with the fields you want to test:

```json
{
    "images": [
        {
            "src": "https://example.com/mockup.jpg",
            "variant_ids": [12345],
            "position": "front",
            "is_default": true
        }
    ],
    "custom_field": "test_value",
    "another_field": {
        "nested": "data"
    }
}
```

#### 2. Enable Test Mode

In `creation-table-functions.php`, set:
```php
$enable_test_injection = true;
```

#### 3. Upload a Product

1. Navigate to WordPress Admin → SiP Plugins → Printify Manager
2. Go to Creation Table tab
3. Select product(s) to upload
4. Choose "Upload to Printify" and execute
5. Complete the upload process

#### 4. Analyze Results

The system generates these files:
- `api_json_test_sent.json` - Exact payload sent to Printify
- `api_json_test_success_response.json` - Printify's creation response
- `api_json_test_full_product.json` - Complete product data after creation
- `api_json_test_summary.json` - Field comparison summary
- `api_json_test_error_response.json` - Error details (if upload fails)

#### 5. Disable Test Mode

After testing, set:
```php
$enable_test_injection = false;
```

### Extending the Test System

The current implementation handles common test fields. To test additional fields:

```php
// Add specific fields:
if (isset($test_data['new_field'])) {
    $product_json['new_field'] = $test_data['new_field'];
    error_log("TEST INJECTION: Added new_field to product JSON");
}

// Or merge all test data (use cautiously):
$product_json = array_merge($product_json, $test_data);
```

### Known Test Results

Through extensive testing, we've confirmed:

1. **Accepted Fields**:
   - `description` - HTML product description
   - `tags` - Array of product tags
   - All documented fields (title, blueprint_id, variants, etc.)

2. **Ignored Fields**:
   - `images` - Printify generates its own mockups
   - `views` - Not recognized
   - `mockups` - Not recognized
   - `default_mockup_position` - Not recognized

3. **Required Behaviors**:
   - `is_printify_express_enabled` must be explicitly set to `false`
   - Empty strings ("") are treated differently than null values
   - Tags must be an array, not a string

### Debug Output

Look for "TEST INJECTION:" messages in WordPress debug.log to confirm test data was applied.

## Other Testing Procedures

### Manual Testing Checklist

When testing plugin functionality:

1. **Product Upload**
   - [ ] Single product upload
   - [ ] Batch upload (multiple products)
   - [ ] Progress dialog displays correctly
   - [ ] Error handling for failed uploads

2. **Field Inheritance**
   - [ ] Template description inherits correctly
   - [ ] Template tags inherit correctly
   - [ ] Child product overrides work
   - [ ] Empty strings handled properly

3. **Table Operations**
   - [ ] Row highlighting updates correctly
   - [ ] Filters work as expected
   - [ ] Pagination maintains state
   - [ ] Selection behavior is correct

### Performance Testing

For large templates (500+ products):
- Monitor memory usage during upload
- Check pagination performance
- Verify progress dialog accuracy
- Test filter responsiveness

## Best Practices

1. **Clean Up After Testing**
   - Delete test result files after analysis
   - Disable test mode when done
   - Remove test data files if not needed

2. **Document Findings**
   - Add confirmed behaviors to architecture documentation
   - Update this guide with new test procedures
   - Share findings with team

3. **Safety First**
   - Always test on development environment first
   - Keep test mode disabled in production
   - Back up templates before testing

## Troubleshooting

### Test Data Not Applied
- Verify `$enable_test_injection = true`
- Check test data file exists and is valid JSON
- Look for "TEST INJECTION:" in debug.log

### Upload Failures
- Check `api_json_test_error_response.json`
- Verify API token is valid
- Ensure required fields are present

### Missing Output Files
- Confirm upload succeeded (check for product ID)
- Verify write permissions on uploads directory
- Check PHP error logs