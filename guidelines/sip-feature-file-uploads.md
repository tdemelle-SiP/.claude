# SiP Feature - File Uploads

This guide documents the file upload patterns used across SiP plugins.

## Implementation Patterns

### 1. Single File Upload

The standard approach for handling single file uploads uses AJAX with FormData.

#### PHP Handler

```php
/**
 * Handle single file upload
 */
function sip_add_local_image() {
    if (!isset($_FILES['file']) || !is_uploaded_file($_FILES['file']['tmp_name'])) {
        return ['error' => 'No file uploaded'];
    }

    $file_name = sanitize_file_name($_FILES['file']['name']);
    $upload_dir = wp_upload_dir();
    $sip_upload_dir = $upload_dir['basedir'] . '/sip-printify-manager/images/';
    $sip_upload_url = $upload_dir['baseurl'] . '/sip-printify-manager/images/';
    $thumb_dir = $sip_upload_dir . 'thumbnails/';
    $thumb_url = $sip_upload_url . 'thumbnails/';

    // Create directories if they don't exist
    foreach ([$sip_upload_dir, $thumb_dir] as $dir) {
        if (!file_exists($dir)) {
            if (!wp_mkdir_p($dir)) {
                return ['error' => 'Failed to create directory: ' . $dir];
            }
        }
    }

    // Move uploaded file
    $destination = $sip_upload_dir . $file_name;
    if (!move_uploaded_file($_FILES['file']['tmp_name'], $destination)) {
        return ['error' => 'Failed to move uploaded file'];
    }

    // Verify image and get dimensions
    $dimensions = @getimagesize($destination);
    if (!$dimensions) {
        @unlink($destination);
        return ['error' => 'Invalid image file'];
    }

    list($width, $height) = $dimensions;
    $file_size = filesize($destination);

    // Create thumbnail
    $thumb_url = sip_create_thumbnail($destination, $thumb_dir, $thumb_url);

    $image_data = array(
        'id'          => uniqid('local_'),
        'name'        => $file_name,
        'size'        => $file_size,
        'width'       => $width,
        'height'      => $height,
        'dimensions'  => $width . 'x' . $height,
        'src'         => $sip_upload_url . $file_name,
        'location'    => 'Local File',
        'upload_time' => current_time('mysql'),
        'thumbnail'   => $thumb_url
    );

    $existing_images = get_option('sip_printify_images', array());
    $existing_images[] = $image_data;
    update_option('sip_printify_images', $existing_images);

    return [
        'images' => $existing_images,
        'image_table_html' => sip_display_image_table($existing_images),
    ];
}
```

#### JavaScript Client

```javascript
function handleImageAdd(e) {
    e.preventDefault();
    e.stopPropagation();
    const files = e.target.files;
    if (files.length > 0) {
        startMultiLocalImageAdd(files);
        $(this).val(''); // Reset the file input
    }
}
```

### 2. Multiple File Upload with Progress Dialog

For multiple file uploads, use the Progress Dialog for better user experience.

```javascript
function startMultiLocalImageAdd(fileList) {
    const files = Array.from(fileList);
    
    if (files.length === 0) {
        SiP.Core.utilities.toast.show('No files selected', 3000);
        return;
    }
    
    return SiP.Core.progressDialog.processBatch({
        items: files,
        batchSize: 1, // Process one file at a time
        dialogOptions: {
            title: 'Uploading Images',
            initialMessage: `Uploading ${files.length} images to your library...`,
            waitForUserOnStart: false,
            waitForUserOnComplete: true
        },
        steps: {
            weights: {
                upload: 70,
                process: 30
            }
        },
        processItemFn: async (file, dialog) => {
            dialog.startStep('upload');
            dialog.updateStatus(`Uploading ${file.name}...`);
            
            const formData = SiP.Core.utilities.createFormData('sip-printify-manager', 'image_action', 'add_local_image');
            formData.append('file', file);
            
            try {
                const response = await SiP.Core.ajax.handleAjaxAction('sip-printify-manager', 'image_action', formData);
                
                dialog.completeStep('upload');
                dialog.startStep('process');
                dialog.updateStatus(`Processing ${file.name}...`);
                dialog.updateStepProgress('process', 1.0);
                dialog.completeStep('process');
                
                return response;
            } catch (error) {
                throw error;
            }
        },
        onAllComplete: function(successCount, failureCount, errors) {
            if (failureCount > 0) {
                SiP.Core.utilities.toast.show(`Uploaded ${successCount} images with ${failureCount} errors`, 5000);
            }
        },
        onCancel: function() {
            SiP.Core.utilities.toast.show('Image upload cancelled', 3000);
        }
    });
}
```

### 3. Drag and Drop Support

Implement drag and drop functionality for better user experience.

```javascript
function attachImageEventListeners() {
    const $uploadArea = $('#image-upload-area');
    $uploadArea.off('dragover').on('dragover', handleDragOver);
    $uploadArea.off('dragleave').on('dragleave', handleDragLeave);
    $uploadArea.off('drop').on('drop', handleImageDrop);
    
    $('#image-file-input').off('change').on('change', handleImageAdd);
    
    $('#select-images-button').off('click').on('click', function() {
        $('#image-file-input').click();
    });
}

function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).addClass('dragging');
}

function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).removeClass('dragging');
}

function handleImageDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).removeClass('dragging');
    startMultiLocalImageAdd(e.originalEvent.dataTransfer.files);
}
```

### 4. Upload to External Service (Printify Example)

For uploading to external services, encode the file as base64 and send via API.

```php
function sip_upload_image_to_printify() {
    $local_image_data = json_decode(stripslashes($_POST['image']), true);

    if (empty($local_image_data) || !isset($local_image_data['src'])) {
        return ['error' => 'Invalid image data'];
    }

    $file_path = str_replace(site_url('/'), ABSPATH, $local_image_data['src']);
    if (!file_exists($file_path)) {
        return ['error' => 'File not found'];
    }

    $encrypted_token = get_option('printify_bearer_token');
    $token = sip_decrypt_token($encrypted_token);
    if (!$token) {
        return ['error' => 'Authentication error'];
    }

    $file_contents = file_get_contents($file_path);
    if (!$file_contents) {
        return ['error' => 'File read error'];
    }

    $response = wp_remote_post('https://api.printify.com/v1/uploads/images.json', [
        'headers' => [
            'Authorization' => 'Bearer ' . $token,
            'Content-Type'  => 'application/json'
        ],
        'body' => json_encode(array_merge(
            map_internal_to_printify($local_image_data),
            ['contents' => base64_encode($file_contents)]
        )),
        'timeout' => 60
    ]);

    if (is_wp_error($response)) {
        return ['error' => 'API error occurred'];
    }

    $body = wp_remote_retrieve_body($response);
    $result = json_decode($body, true);

    if (!$result || !isset($result['id'])) {
        return ['error' => 'Invalid API response'];
    }

    return ['printify_data' => $result];
}
```

### 5. Thumbnail Creation

Create thumbnails for uploaded images using WordPress image editor.

```php
function sip_create_thumbnail($original_path, $thumb_dir, $thumb_url) {
    $editor = wp_get_image_editor($original_path);
    if (is_wp_error($editor)) {
        return sip_get_placeholder_icon();
    }

    $editor->resize(256, 256, true);

    $orig_filename = basename($original_path);
    $filename_parts = explode('.', $orig_filename);
    $ext = array_pop($filename_parts);
    $base = implode('.', $filename_parts);
    $thumb_filename = wp_unique_filename($thumb_dir, $base . '_thumb.' . $ext);
    $thumb_path = $thumb_dir . $thumb_filename;

    $editor->set_quality(90);
    $result = $editor->save($thumb_path);

    if (is_wp_error($result)) {
        return sip_get_placeholder_icon();
    }

    return $thumb_url . $thumb_filename;
}

function sip_get_placeholder_icon() {
    return plugin_dir_url(__FILE__) . 'assets/thumbnail-icon.png';
}
```

## File Storage Structure

SiP plugins use a standardized directory structure for uploaded files:

```
wp-content/uploads/
├── sip-printify-manager/
│   ├── images/
│   │   ├── original-file.jpg
│   │   └── ...
│   └── thumbnails/
│       ├── original-file_thumb.jpg
│       └── ...
```

## Security Considerations

1. **File Type Validation**: Always validate file types before processing
```php
$dimensions = @getimagesize($destination);
if (!$dimensions) {
    @unlink($destination);
    return ['error' => 'Invalid image file'];
}
```

2. **Filename Sanitization**: Use WordPress sanitization
```php
$file_name = sanitize_file_name($_FILES['file']['name']);
```

3. **Directory Creation**: Use WordPress functions
```php
if (!wp_mkdir_p($dir)) {
    return ['error' => 'Failed to create directory: ' . $dir];
}
```

## Integration with AJAX System

File uploads integrate with the standard SiP AJAX system:

```javascript
// Create form data with file
const formData = SiP.Core.utilities.createFormData('sip-printify-manager', 'image_action', 'add_local_image');
formData.append('file', file);

// Send via AJAX
const response = await SiP.Core.ajax.handleAjaxAction('sip-printify-manager', 'image_action', formData);
```

## HTML Structure

Basic file upload interface:

```html
<div id="image-upload-area" class="upload-area">
    <p>Drag and drop images here or</p>
    <button type="button" id="select-images-button" class="button">Select Images</button>
    <input type="file" id="image-file-input" multiple accept="image/*" style="display: none;">
</div>
```

## Error Handling

Always provide clear error messages:

```php
if (!isset($_FILES['file']) || !is_uploaded_file($_FILES['file']['tmp_name'])) {
    return ['error' => 'No file uploaded'];
}

if (!move_uploaded_file($_FILES['file']['tmp_name'], $destination)) {
    return ['error' => 'Failed to move uploaded file'];
}
```

## Best Practices

1. **Use Progress Dialogs**: For multiple file uploads or long operations
2. **Create Thumbnails**: For better performance in galleries
3. **Validate File Types**: Check files before processing
4. **Provide Feedback**: Use toasts for success/error messages
5. **Clean Up**: Remove temporary files on error
6. **Secure Storage**: Store files outside the plugin directory
7. **Use Unique IDs**: Generate unique identifiers for uploaded files