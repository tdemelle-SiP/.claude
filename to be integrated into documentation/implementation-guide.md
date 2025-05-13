# Implementation Guide for New Console Log Pattern

This guide shows how to implement the new console log pattern in the `handleBatchImageAddToProduct` function and related functions. The new pattern uses a visual hierarchy with vertical lines and colored icons to make the asynchronous flow more visible.

## Implementation Steps

1. Update the main function with the new pattern:

```javascript
function handleBatchImageAddToProduct(selectedImages, targetCells, targetColumn) {
    console.log('👍 Add to New Products action initiated with', selectedImages.length, 'images');
    console.log('─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ❌ Starting batch image processing for', selectedImages.length, 'images─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─');
    
    // Count local images that need uploading
    const localImages = selectedImages.filter(img => !img.src.includes('pfy-prod-image-storage'));
    
    // Process images using the progress dialog batch processor
    console.log('📊🟦 Initializing progress meter');
    
    // Rest of the function...
}
```

2. Update the process item function with the new pattern:

```javascript
processItemFn: async function(image, dialog) {
    try {
        // Update status message
        console.log('📊🟦 Progress meter update - Starting to process image');
        dialog.updateStatus(`Processing image "${image.name}"...`);
        
        // Step 1: Get Printify data (upload if needed)
        let printifyData;
        if (!image.src.includes('pfy-prod-image-storage')) {
            console.log('📊🟦 Progress meter update - Uploading image');
            dialog.updateStatus(`Uploading image "${image.name}" to Printify...`);
            
            console.log('│');
            console.log('│ ⭕ Making async call to upload image to Printify');
            printifyData = await handleUploadImageToPrintify(image);
            console.log('│ 🔴 Received async response - Upload complete');
            
            console.log('│');
            console.log('│ ⭕ Making async call to update image record');
            await updateUploadedImageRecord(image.id, printifyData);
            console.log('│ 🔴 Received async response - Update complete');
        } else {
            console.log('│ 💠 Using existing Printify image');
            printifyData = {
                id: image.id,
                name: image.name,
                src: image.src,
                type: image.type || 'image/jpeg'
            };
        }
        
        // Step 2: Generate title if needed
        let productTitle = null;
        const titleCheckbox = document.getElementById('update-titles');
        if (titleCheckbox && titleCheckbox.checked) {
            console.log('📊🟦 Progress meter update - Generating title');
            dialog.updateStatus(`Generating title for "${image.name}"...`);
            try {
                console.log('│');
                console.log('│ ⭕ Making async call to generate product title');
                productTitle = await generateProductTitle(image.name, targetColumn);
                console.log('│ 🔴 Received async response with generated title');
            } catch (error) {
                console.error('❌ Error generating title:', error);
                dialog.showError(`Warning: Could not generate title: ${error.message}`);
                // Continue without a title
            }
        }
        
        // Step 3: Create the product
        console.log('📊🟦 Progress meter update - Creating product');
        dialog.updateStatus(`Creating product from "${image.name}"...`);
        
        console.log('│');
        console.log('│ ⭕ Making async call to create new product');
        await createNewProduct(printifyData, targetColumn, productTitle);
        console.log('│ 🔴 Received async response - Product creation complete');
        
        console.log('│ 💠 Completing action for this image');
        return { success: true };
    } catch (error) {
        // Handle any errors in the process
        console.error('❌ Error processing image:', error);
        dialog.showError(`Failed to process ${image.name}: ${error.message}`);
        return { success: false, error };
    }
}
```

3. Update the completion handler with the new pattern:

```javascript
onAllComplete: async function(successCount, failureCount, errors) {
    console.log('❌ All batches complete. Success:', successCount, 'Failure:', failureCount);
    console.log('📊🟦 Progress meter update - All items processed');
    
    // If no successful operations, just return
    if (successCount === 0) {
        console.log('💠 Completing action - No successful operations');
        return { success: false };
    }
    
    // Mark the creation table as dirty to trigger a save prompt
    if (SiP.PrintifyManager.creationTableSetupActions?.utils?.setCreationTableIsDirty) {
        console.log('💠 Performing action - Marking creation table as dirty');
        SiP.PrintifyManager.creationTableSetupActions.utils.setCreationTableIsDirty(true);
    }
    
    // Reload template and images with pragmatic approach
    try {
        console.log('📊🟦 Progress meter update - Starting reload phase');
        this.updateStatus('Reloading template and images...');
        
        // Get template title
        console.log('💠 Performing action - Getting template data');
        const templateData = SiP.PrintifyManager.creationTableSetupActions?.utils?.getCreationTemplateWipData();
        const templateTitle = templateData?.data?.template_title;
        
        // Reload template if possible - PRAGMATIC APPROACH
        if (templateTitle && typeof SiP.PrintifyManager.creationTableSetupActions?.utils?.checkAndLoadTemplateWip === 'function') {
            // Call the function but don't assume it returns a Promise
            console.log('⭕ Making async call to reload template');
            SiP.PrintifyManager.creationTableSetupActions.utils.checkAndLoadTemplateWip(templateTitle);
            console.log('📊🟦 Progress meter update - Template reload requested');
            this.updateStatus('Template reload requested.');
            
            // Wait a moment for the template to reload before reloading images
            console.log('💠 Performing action - Waiting for template reload');
            await new Promise(resolve => setTimeout(resolve, 500));
            
            // Now reload images
            console.log('📊🟦 Progress meter update - Reloading image table');
            this.updateStatus('Reloading image table...');
            
            console.log('│');
            console.log('│ ⭕ Making async call to reload shop images');
            await handleReFetchShopImages();
            console.log('│ 🔴 Received async response - Reload data received');
            
            console.log('📊🟦 Progress meter update - Reload complete');
            this.updateStatus('Image table reloaded successfully.');
        }
        
        console.log('💠 Completing action - All operations successful');
        return { success: true };
    } catch (error) {
        // Handle any errors in the reload process
        console.error('❌ Error reloading data:', error);
        this.showError(`Error reloading data: ${error.message}`);
        return { success: true }; // Still return success since the products were created
    }
}
```

4. Update the helper functions with the new pattern:

```javascript
async function handleUploadImageToPrintify(imageData) {
    console.log('❌ Starting upload to Printify for image:', imageData.name);
    
    try {
        // Validate input
        console.log('│ ├─💠 Performing action - Validating input data');
        if (!imageData || !imageData.name) {
            throw new Error('Invalid image data provided for upload');
        }
        
        // Create form data with image information
        console.log('│ ├─💠 Performing action - Creating form data');
        const formData = SiP.Core.utilities.createFormData('image_action', 'upload_image_to_printify');
        formData.append('image', JSON.stringify(imageData));
        
        // Send the request and await the response
        console.log('│ └─⭕ Making AJAX request to upload image');
        const response = await SiP.Core.ajax.handleAjaxAction('image_action', formData);
        
        // Rest of the function...
    } catch (error) {
        // Error handling...
    }
}

async function updateUploadedImageRecord(localId, printifyData) {
    console.log('❌ Updating image record for localId:', localId);
    
    try {
        // Validate input
        console.log('│ ├─💠 Performing action - Validating input data');
        if (!localId || !printifyData || !printifyData.id) {
            throw new Error('Invalid data provided for image record update');
        }
        
        // Create form data with normalized Printify data
        console.log('│ ├─💠 Performing action - Creating form data with normalized Printify data');
        const formData = SiP.Core.utilities.createFormData('image_action', 'update_image_record');
        formData.append('local_id', localId);
        formData.append('printify_data', JSON.stringify({
            // Data...
        }));
        
        // Send the request and await the response
        console.log('│ └─⭕ Making AJAX request to update image record');
        const response = await SiP.Core.ajax.handleAjaxAction('image_action', formData);
        
        // Rest of the function...
    } catch (error) {
        // Error handling...
    }
}

async function generateProductTitle(imageName, targetColumn) {
    console.log('❌ Generating product title for image:', imageName);
    
    try {
        // Validate input parameters
        console.log('│ ├─💠 Performing action - Validating input parameters');
        if (!imageName) {
            throw new Error('Image name is required for title generation');
        }
        
        if (targetColumn === undefined || targetColumn === null) {
            throw new Error('Target column is required for title generation');
        }
        
        console.log('Using target column:', targetColumn);
        
        // Get template data with defensive access
        console.log('│ ├─💠 Performing action - Getting template data');
        const creationTemplateWipData = SiP.PrintifyManager.creationTableSetupActions?.utils?.getCreationTemplateWipData();
        
        // Validate template data
        console.log('│ ├─💠 Performing action - Validating template data');
        if (!creationTemplateWipData?.data?.template_title) {
            throw new Error('No template data available for title generation');
        }
        
        // Rest of the function...
    } catch (error) {
        // Error handling...
    }
}
```

## Console Log Pattern Legend

- **Section Headers**: Use dashed lines to mark the beginning of a major section
  ```
  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ❌ Starting batch image processing ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  ```

- **Progress Meter Updates**: Use 📊🟦 for progress meter updates
  ```
  📊🟦 Initializing progress meter
  📊🟦 Progress meter update - Starting to process image
  ```

- **Async Calls**: Use ⭕ for starting async calls and 🔴 for receiving responses
  ```
  │ ⭕ Making async call to upload image to Printify
  │ 🔴 Received async response - Upload complete
  ```

- **Actions**: Use 💠 for actions being performed
  ```
  │ 💠 Using existing Printify image
  💠 Performing action - Marking creation table as dirty
  ```

- **Nested Actions**: Use vertical lines and indentation to show hierarchy
  ```
  │ ├─💠 Performing action - Validating input data
  │ ├─💠 Performing action - Creating form data
  │ └─⭕ Making AJAX request to upload image
  ```

## Benefits of the New Pattern

1. **Visual Hierarchy**: The vertical lines and indentation make it clear which actions belong to which parent operation.

2. **Color Coding**: The colored icons make it easy to distinguish between different types of operations.

3. **Consistent Structure**: The pattern provides a consistent way to log asynchronous operations throughout the codebase.

4. **Improved Debugging**: The pattern makes it easier to trace the flow of execution through the console logs.
