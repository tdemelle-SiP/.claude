# Progress Dialog (Batch Operations)

*Last Updated: January 2025 - Added processBatchFn support, batch item display methods, removed retry logic*

This guide explains how to implement batch processing operations using the SiP Core progress dialog. Use this when processing multiple items to provide visual feedback and prevent timeouts.

## When to Use Progress Dialog

Use the progress dialog for operations such as those often used with [batch data operations](./sip-plugin-data-storage.md#batch-operations):
- Operations processing multiple items (bulk updates, imports, exports)
- Long-running operations that might timeout 
- Any operation where users need visual progress feedback
- Multi-step processes that take more than a few seconds

## Basic Implementation

### Simple Batch Processing

For straightforward batch operations, use the simplified `processBatch` method:

```javascript
function processMultipleItems(items) {
    return SiP.Core.progressDialog.processBatch({
        items: items,                  
        batchSize: 5,                  // Process 5 items at a time
        
        dialogOptions: {
            title: 'Processing Items',
            initialMessage: `Processing ${items.length} items...`,  // Shows before user clicks Continue
            waitForUserOnStart: false,   // true shows Continue button first
            waitForUserOnComplete: true   // true shows Close button at end
        },
        
        processItemFn: async function(item, dialog) {
            try {
                const result = await processItem(item);
                return { success: true };
            } catch (error) {
                return { success: false, error: error.message };
            }
        },
        
        onAllComplete: function(successCount, failureCount, errors) {
            refreshDataTable();  // Refresh your UI
        }
    });
}
```

## Manual Progress Dialog Control

### Step 1: Create the Dialog

```javascript
const dialog = SiP.Core.progressDialog.create({
    // Required settings
    title: 'Batch Operation',           
    
    // Optional settings
    details: 'Processing your items...',
    totalItems: items.length,           
    waitForUserOnStart: false,          // Show "Continue" button at start
    waitForUserOnComplete: true,        // Show "Close" button when done
    width: 500,                         
    closeOnEscape: false               
});

// Start the dialog if not waiting for user
dialog.start();
```

### Step 2: Update Progress During Processing

```javascript
for (let i = 0; i < items.length; i++) {
    const item = items[i];
    
    // Update progress bar and status
    dialog.updateProgress(i + 1, items.length);
    dialog.updateStatus(`Processing item ${i + 1} of ${items.length}: ${item.name}`);
    
    try {
        const result = await processItem(item);
        
    } catch (error) {
        dialog.showError(`Failed to process ${item.name}: ${error.message}`);
    }
    
    // Check if user cancelled
    if (dialog.isCancelled()) {
        break;
    }
}
```

### Step 3: Complete the Dialog

```javascript
// Show completion summary
dialog.complete(successCount, errorCount, errors);

// Or close immediately
dialog.close();
```

## Multi-Step Operations

For complex workflows with multiple phases. For related AJAX implementation, see the [AJAX Guide](./sip-plugin-ajax.md):

### Define Steps with Weights

```javascript
const dialog = SiP.Core.progressDialog.create({
    title: 'Import Products',
    
    steps: {
        weights: {
            validate: 20,   // 20% of progress bar
            upload: 30,     // 30% of progress bar
            process: 40,    // 40% of progress bar
            finalize: 10    // 10% of progress bar
        },
        batchCount: 1      // Number of batches (optional, default: 1)
    }
});

dialog.start();
```

Note: When using `processBatch`, set `batchCount` to the number of items to properly distribute step weights across all batches.

### Execute Each Step

```javascript
// Validation phase
dialog.startStep('validate');
dialog.updateStatus('Validating import file...');
await validateImportFile(file);
dialog.completeStep('validate');

// Upload phase
dialog.startStep('upload');
dialog.updateStatus('Uploading file...');
await uploadFile(file);
dialog.completeStep('upload');

// Processing phase
dialog.startStep('process');
for (let i = 0; i < items.length; i++) {
    dialog.updateStatus(`Processing item ${i + 1} of ${items.length}`);
    await processItem(items[i]);
}
dialog.completeStep('process');

// Finalize phase
dialog.startStep('finalize');
dialog.updateStatus('Finalizing import...');
await finalizeImport();
dialog.completeStep('finalize');

// Complete
dialog.complete(successCount, errorCount);
```

## Real-World Example: Upload with Sequential Operations

Here's an example showing dynamic status updates and dialog reuse from the SiP Printify Manager:

```javascript
// Upload products then reload the product table in the same dialog
SiP.Core.progressDialog.processBatch({
    items: selectedProducts,
    batchSize: 1,
    
    dialogOptions: {
        title: 'Printify Product Upload',
        initialMessage: hasUnsavedChanges 
            ? 'Press Continue to Save Changes and Upload Selected Products'
            : `${selectedProducts.length} items selected for processing`,
        waitForUserOnStart: true,
        waitForUserOnComplete: true
    },
    
    processItemFn: async (productId, dialog) => {
        // Dynamic status update when starting
        if (!processStarted) {
            dialog.updateStatus(`Processing ${selectedProducts.length} items`);
            processStarted = true;
        }
        
        // Process individual item
        dialog.updateStatus(`Uploading product "${productTitle}"...`);
        const result = await uploadProduct(productId);
        return result;
    },
    
    onAllComplete: async function(successCount, failureCount) {
        const dialog = this; // 'this' is the dialog instance
        const totalItems = successCount + failureCount;
        
        // Update status to show completion
        dialog.updateStatus(`${totalItems} items processed`);
        
        // Continue with reload operation in same dialog
        dialog.updateStatus('Product upload complete, reloading product table...');
        await SiP.PrintifyManager.productActions.fetchShopProductsInChunks(null, dialog);
    }
});
```

## Real-World Example: Bulk Product Update

Here's a complete example from the SiP Printify Manager:

```javascript
SiP.PrintifyManager.productActions = (function($, ajax, utilities) {
    
    function bulkUpdateProducts(selectedProducts) {
        // Create progress dialog
        const dialog = SiP.Core.progressDialog.create({
            title: 'Updating Products',
            details: `Updating ${selectedProducts.length} products...`,
            totalItems: selectedProducts.length,
            waitForUserOnStart: false,
            waitForUserOnComplete: true
        });
        
        dialog.start();
        
        let successCount = 0;
        let errorCount = 0;
        let errors = [];
        
        // Process each product
        processNextProduct(0);
        
        function processNextProduct(index) {
            if (index >= selectedProducts.length || dialog.isCancelled()) {
                dialog.complete(successCount, errorCount, errors);
                return;
            }
            
            const product = selectedProducts[index];
            
            // Update dialog
            dialog.updateProgress(index + 1, selectedProducts.length);
            dialog.updateStatus(`Updating product: ${product.name}`);
            
            // Create form data
            const formData = utilities.createFormData(
                'sip-printify-manager',
                'product_action',
                'update_product'
            );
            formData.append('product_id', product.id);
            formData.append('product_data', JSON.stringify(product));
            
            // Send AJAX request
            ajax.handleAjaxAction(
                'sip-printify-manager',
                'product_action',
                formData
            )
            .then(function(response) {
                successCount++;
                processNextProduct(index + 1);
            })
            .catch(function(error) {
                errorCount++;
                errors.push({
                    item: product.name,
                    error: error.message
                });
                dialog.showError(`Failed to update ${product.name}: ${error.message}`);
                processNextProduct(index + 1);
            });
        }
    }
    
    return {
        bulkUpdateProducts: bulkUpdateProducts
    };
    
})(jQuery, SiP.Core.ajax, SiP.Core.utilities);
```

## Dialog Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| title | string | Required | Dialog title |
| initialMessage | string | '' | Primary message shown before processing starts |
| secondaryInitialMessage | string | '' | Secondary message shown before processing starts |
| progressMessage | string | '' | Primary message template during processing (supports {stepCount}, {count}, {item}) |
| secondaryProgressMessage | string | '' | Secondary message template during processing (supports {name}) |
| completionMessage | string | '' | Primary message template when complete (supports {successCount}, {item}) |
| secondaryCompletionMessage | string | '' | Secondary message when complete |
| item | string | 'item' | Singular name of items being processed |
| hideInitialOnStart | boolean | false | Hide initial messages when processing starts |
| totalItems | number | 0 | Total items to process |
| waitForUserOnStart | boolean | false | Show "Continue" button at start |
| waitForUserOnComplete | boolean | true | Show "Close" button when done |
| deferCompletion | boolean | false | Defer dialog completion when onAllComplete is provided (for multi-stage operations) |
| width | number | 500 | Dialog width in pixels |
| closeOnEscape | boolean | false | Allow ESC key to close |
| steps | object | null | Multi-step configuration |

## Methods Reference

| Method | Description |
|--------|-------------|
| `start()` | Start the dialog (if not waiting for user) |
| `updateProgress(current, total)` | Update progress bar |
| `updateStatus(message, variables)` | Update status text with optional variables for template substitution |
| `showError(message)` | Display error message |
| `isCancelled()` | Check if user cancelled |
| `complete(success, errors, errorList)` | Show completion summary |
| `close()` | Close dialog immediately |
| `startStep(stepName)` | Start a named step |
| `completeStep(stepName)` | Complete a named step |
| `setBatchItems(items)` | Display list of items being processed in batch |
| `addBatchItems(items)` | Add items to the top of the existing batch list (cumulative display) |
| `updateBatchItem(index, updates)` | Update status of a specific batch item |
| `showBatchItems()` | Show the batch items display area |
| `hideBatchItems()` | Hide the batch items display area |
| `clearBatchItems()` | Clear all batch items |

## ProcessBatchFn vs ProcessItemFn

The progress dialog supports two processing approaches:

### ProcessItemFn (Sequential Processing)
Processes items one at a time. Good for operations that must be sequential:

```javascript
processItemFn: async function(item, dialog) {
    // Process a single item
    const result = await processSingleItem(item);
    return { success: true };
}
```

### ProcessBatchFn (Batch Processing)
Processes multiple items at once. More efficient for operations that can be parallelized:

```javascript
processBatchFn: async (batch, batchIndex, dialog) => {
    // Process entire batch at once
    // batch: array of items in this batch
    // batchIndex: 0-based index of current batch
    // dialog: the progress dialog instance
    
    // Example: upload multiple files in one request
    const formData = new FormData();
    batch.forEach(file => formData.append('files[]', file));
    
    const response = await uploadBatch(formData);
    return { success: true, results: response };
}
```

**When to use ProcessBatchFn:**
- File uploads (send multiple files in one request)
- Database operations (batch inserts/updates)
- API calls that support batch operations
- Any operation where processing multiple items together is more efficient

## Best Practices

1. **Always provide progress feedback** - Update the dialog regularly
2. **Handle cancellation** - Check `isCancelled()` in loops
3. **Show meaningful status messages** - Tell users what's happening
4. **Dynamic status updates** - Change status text as operations progress (e.g., "3 items selected" → "Processing 3 items" → "3 items processed")
5. **Batch operations** - Process multiple items in a single request when possible using `processBatchFn`
6. **Error handling** - Continue processing other items after errors (no retry logic)
7. **Use processBatch for simple cases** - It handles all the boilerplate
8. **Visual feedback for batch items** - Use setBatchItems() and updateBatchItem() to show individual item status

## Template Variables

The following variables are available for use in message templates:

| Variable | Description | Example |
|----------|-------------|---------|
| `{count}` | Total number of items | "Processing {count} products" → "Processing 10 products" |
| `{stepCount}` | Current item number | "Item {stepCount} of {count}" → "Item 3 of 10" |
| `{successCount}` | Number of successful items | "{successCount} items completed" → "8 items completed" |
| `{item}` | Item name (singular) | "Uploading {item}" → "Uploading product" |
| `{name}` | Current item's name | "Processing {name}" → "Processing Blue Widget" |

## Common Pitfalls

1. **Don't process too many items at once** - Use reasonable batch sizes
2. **Don't forget to handle errors** - Always catch and display errors
3. **Don't block the UI** - Use async/await or promises
4. **Don't skip progress updates** - Users need feedback
5. **Don't implement retry logic** - The progress dialog no longer supports automatic retries. Handle errors gracefully and let users retry the entire operation if needed

## Batch Item Display

When processing multiple items and you want to show the user which specific items are being processed:

### Basic Usage

```javascript
// In your processBatchFn
processBatchFn: async (batch, batchIndex, dialog) => {
    // Show the items in this batch
    dialog.setBatchItems(batch.map(item => item.name));
    
    // Process each item
    for (let i = 0; i < batch.length; i++) {
        // Update item status as processing
        dialog.updateBatchItem(i, { status: 'processing' });
        
        try {
            await processItem(batch[i]);
            // Update item status as complete
            dialog.updateBatchItem(i, { status: 'complete' });
        } catch (error) {
            // Update item status as error
            dialog.updateBatchItem(i, { status: 'error' });
        }
    }
}
```

### Available Status Values

| Status | Icon | Color | Description |
|--------|------|-------|-------------|
| `pending` | ○ | Gray | Item waiting to be processed |
| `processing` | ⟳ | Blue (animated) | Item currently being processed |
| `uploading` | ⟳ | Blue (animated) | Item being uploaded |
| `complete` | ✓ | Green | Item successfully processed |
| `success` | ✓ | Green | Alternative to complete |
| `error` | ✗ | Red | Item failed to process |
| `failed` | ✗ | Red | Alternative to error |
| `warning` | ⚠ | Yellow | Item processed with warnings |

### Full Example with File Upload

This example from the SiP Printify Manager shows a complete multi-step batch file upload with validation:

```javascript
SiP.Core.progressDialog.processBatch({
    items: files,
    batchSize: 5,
    
    dialogOptions: {
        title: 'Uploading Images',
        initialMessage: `Uploading ${files.length} images to your library...`,
        waitForUserOnStart: false,
        waitForUserOnComplete: true
    },
    
    steps: {
        weights: {
            validate: 10,   // 10% for validation
            upload: 70,     // 70% for upload
            process: 20     // 20% for processing results
        }
    },
    
    processBatchFn: async (batch, batchIndex, dialog) => {
        const batchNumber = batchIndex + 1;
        const totalBatches = Math.ceil(files.length / 5);
        
        // Show batch files with initial pending status
        dialog.setBatchItems(batch.map(f => f.name));
        dialog.showBatchItems();
        dialog.updateStatus(`Processing batch ${batchNumber} of ${totalBatches}`);
        
        // STEP 1: Validate all files
        dialog.startStep('validate');
        dialog.updateStatus(`Validating ${batch.length} images...`);
        
        const validationPromises = batch.map(async (file, index) => {
            dialog.updateBatchItem(index, { status: 'processing' });
            const dimensions = await checkImageDimensions(file);
            
            if (dimensions && (dimensions.width > 1024 || dimensions.height > 1024)) {
                dialog.log(`⚠️ ${file.name}: Large image detected (${dimensions.width}x${dimensions.height}px)`, 'warning');
                dialog.updateBatchItem(index, { status: 'warning' });
            } else {
                dialog.updateBatchItem(index, { status: 'success' });
            }
            return { file, dimensions, index };
        });
        
        await Promise.all(validationPromises);
        dialog.completeStep('validate');
        
        // STEP 2: Upload all files in one request
        dialog.startStep('upload');
        dialog.updateStatus(`Uploading ${batch.length} images...`);
        
        // Update all items to uploading status
        batch.forEach((file, index) => {
            dialog.updateBatchItem(index, { status: 'uploading' });
        });
        
        // Create form data with all files
        const formData = new FormData();
        formData.append('action', 'add_local_images_batch');
        batch.forEach(file => {
            formData.append('files[]', file);
        });
        
        try {
            const response = await fetch(ajaxurl, {
                method: 'POST',
                body: formData
            });
            
            if (!response.ok) throw new Error('Upload failed');
            
            // Update all items to success
            batch.forEach((file, index) => {
                dialog.updateBatchItem(index, { status: 'success' });
                dialog.log(`✓ ${file.name} uploaded`, 'success');
            });
            
            dialog.completeStep('upload');
        } catch (error) {
            // Update all items to error on failure
            batch.forEach((file, index) => {
                dialog.updateBatchItem(index, { status: 'error' });
                dialog.log(`✗ ${file.name} failed: ${error.message}`, 'error');
            });
            throw error;
        }
        
        // STEP 3: Process results
        dialog.startStep('process');
        dialog.updateStatus(`Processing ${batch.length} results...`);
        // ... process the response data
        dialog.completeStep('process');
        
        return { success: true };
    },
    
    onAllComplete: function(successCount, failureCount, errors) {
        // Refresh the image table once at the end
        if (successCount > 0) {
            refreshImageTable();
        }
    }
});
```

## Advanced Patterns

### Pre-Processing Before Batch Operations

When you need to perform an operation (like saving) before processing items:

```javascript
let preprocessCompleted = false;

SiP.Core.progressDialog.processBatch({
    items: items,
    
    dialogOptions: {
        title: 'Processing',
        initialMessage: 'Pre-processing required before continuing.',
        waitForUserOnStart: true
    },
    
    processItemFn: async (item, dialog) => {
        // Do preprocessing on first item only
        if (!preprocessCompleted) {
            dialog.updateStatus('Performing pre-processing...');
            await doPreprocessing();
            preprocessCompleted = true;
            dialog.updateStatus('Starting main processing...');
        }
        
        // Process item normally
        return await processItem(item, dialog);
    }
});
```

### Reusing Progress Dialogs Across Operations

When you have sequential operations (like uploading then reloading), you can reuse the same dialog:

```javascript
// In the processBatch onAllComplete callback
onAllComplete: async function(successCount, failureCount, errors) {
    // 'this' refers to the dialog instance
    const dialog = this;
    
    // Update status for the next operation
    dialog.updateStatus('Upload complete, reloading data...');
    
    // Pass the dialog to another operation
    await anotherOperation(data, dialog);
}

// Function that accepts an existing dialog
async function anotherOperation(data, existingDialog) {
    let dialog;
    let shouldCloseDialog = true;
    
    if (existingDialog) {
        dialog = existingDialog;
        shouldCloseDialog = false; // Don't close dialog we didn't create
    } else {
        dialog = SiP.Core.progressDialog.create({...});
        dialog.start();
    }
    
    // Do your work...
    
    // Only close if we created it
    if (shouldCloseDialog) {
        dialog.complete(...);
    }
}
```

### Using deferCompletion for Multi-Stage Operations

When you need to perform multiple operations in sequence without showing the close button between stages, use the `deferCompletion` option:

```javascript
SiP.Core.progressDialog.processBatch({
    items: selectedProducts,
    batchSize: 1,
    
    dialogOptions: {
        title: 'Multi-Stage Operation',
        waitForUserOnStart: true,
        waitForUserOnComplete: true,
        deferCompletion: true  // Prevents close button between stages
    },
    
    processItemFn: async (item, dialog) => {
        // Process each item
        return await processItem(item);
    },
    
    // When deferCompletion is true, onAllComplete receives a 4th parameter
    onAllComplete: async function(successCount, failureCount, errors, completeDialog) {
        const dialog = this;
        
        try {
            // Stage 2: Perform additional operations
            dialog.updateStatus('Stage 1 complete, starting stage 2...');
            await performStage2Operations(dialog);
            
            // Stage 3: Final operations
            dialog.updateStatus('Stage 2 complete, finalizing...');
            await performFinalOperations(dialog);
            
            // Now manually complete the dialog
            completeDialog();
            
        } catch (error) {
            dialog.showError(`Error in post-processing: ${error.message}`);
            // Always complete the dialog, even on error
            completeDialog();
        }
    }
});
```

### Important Notes

- The progress dialog buttons use fixed text: "Continue" and "Cancel" (cannot be customized)
- The `processItemFn` receives exactly two parameters: `(item, dialog)`
- The `processBatchFn` receives exactly three parameters: `(batch, batchIndex, dialog)`
- The `onAllComplete` callback context (`this`) is the dialog instance
- When `deferCompletion: true`, `onAllComplete` receives a 4th parameter: the completion function
- Use `dialog.showError()` to display errors within the dialog
- Throw an exception from `processItemFn` or `processBatchFn` to stop all processing
- Retry logic has been removed - errors fail immediately without automatic retries

## Related Guides
- For testing batch operations, refer to the [Testing Guide](./sip-development-testing.md)