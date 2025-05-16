# Progress Dialog Implementation Guide

## What is the Progress Dialog?

The Progress Dialog shows users that your code is working by displaying a progress bar and status messages. It prevents users from thinking the system is frozen during long operations.

## Adding Progress Dialog to Your Function

### Step 1: At the Beginning of Your Function

Add this code at the start of your function to create the dialog:

```javascript
// Create the progress dialog
const dialog = SiP.Core.progressDialog.create({
    // REQUIRED SETTINGS
    title: 'Your Operation Title',              // Shows at the top of the dialog
    
    // OPTIONAL SETTINGS - Choose what you need
    details: 'Description of what is happening', // Longer explanation text
    totalItems: items.length,                    // How many items you're processing
    
    // Dialog behavior
    waitForUserOnStart: false,    // true = show "Continue" button, false = start immediately
    waitForUserOnComplete: true,  // true = show "Close" button, false = auto-close when done
    
    // Dialog appearance
    width: 500,                   // Width in pixels
    closeOnEscape: false          // Whether Escape key can close the dialog
});

// Start the dialog (only needed if waitForUserOnStart is false)
dialog.start();
```

### Step 2: During Your Processing Loop

Add these lines inside your processing loop to update the progress:

```javascript
// Loop through your items
for (let i = 0; i < items.length; i++) {
    // Your existing processing code
    const item = items[i];
    processItem(item);
    
    // UPDATE THE DIALOG - Add these lines
    dialog.updateProgress(i + 1, items.length);  // Update progress bar
    dialog.updateStatus(`Processing item ${i + 1} of ${items.length}: ${item.name}`);  // Update status text
    
    // If there's an error in your processing
    if (errorOccurred) {
        dialog.showError(`Failed to process ${item.name}: ${errorMessage}`);
    }
    
    // Check if user cancelled
    if (dialog.isCancelled()) {
        break;  // Exit the loop if cancelled
    }
}
```

### Step 3: At the End of Your Function

Add this code at the end of your function to complete the dialog:

```javascript
// Complete the dialog
dialog.complete(successCount, errorCount, errors);

// OR if you want to close it immediately
dialog.close();
```

## For Multi-Step Operations

If your function has distinct phases (like upload, process, save), use this approach:

### Step 1: At the Beginning of Your Function

```javascript
const dialog = SiP.Core.progressDialog.create({
    title: 'Your Operation Title',
    details: 'Description of what is happening',
    
    // Define your steps and how much of the progress bar each should take
    steps: {
        weights: {
            upload: 30,     // 30% of the progress bar
            process: 50,    // 50% of the progress bar
            save: 20        // 20% of the progress bar
        }
    }
});

dialog.start();
```

### Step 2: At Each Phase of Your Function

```javascript
// UPLOAD PHASE
dialog.startStep('upload');
dialog.updateStatus('Uploading files...');
// Your upload code here
dialog.completeStep('upload');

// PROCESS PHASE
dialog.startStep('process');
dialog.updateStatus('Processing data...');
// Your processing code here
dialog.completeStep('process');

// SAVE PHASE
dialog.startStep('save');
dialog.updateStatus('Saving results...');
// Your saving code here
dialog.completeStep('save');
```

### Step 3: At the End of Your Function

```javascript
dialog.complete(successCount, errorCount, errors);
```

## For Processing Many Items (Batch Processing)

For functions that process many items, use this simplified approach:

```javascript
function yourFunction(items) {
    // This handles everything for you
    return SiP.Core.progressDialog.processBatch({
        items: items,                  // Array of items to process
        batchSize: 5,                  // How many items to process at once
        
        // Dialog settings
        dialogOptions: {
            title: 'Processing Items',
            initialMessage: `Processing ${items.length} items...`,
            waitForUserOnStart: false,
            waitForUserOnComplete: true
        },
        
        // This function processes each item
        processItemFn: async function(item, dialog) {
            try {
                // Your processing code here
                const result = await processItem(item);
                return { success: true };
            } catch (error) {
                return { success: false, error: error.message };
            }
        },
        
        // This runs when all items are processed
        onAllComplete: function(successCount, failureCount, errors) {
            // Code to run after everything is done
            refreshData();  // For example, refresh your data display
        }
    });
}
```

## Common Settings to Customize

- **title**: The dialog title (keep it short)
- **details**: Longer explanation of what's happening
- **totalItems**: Number of items being processed
- **waitForUserOnStart**: Set to true to show a "Continue" button before starting
- **waitForUserOnComplete**: Set to true to show a "Close" button when finished
- **width**: Dialog width in pixels (default is 500)

That's it! Add these code blocks to your function and customize the text to match your operation.
