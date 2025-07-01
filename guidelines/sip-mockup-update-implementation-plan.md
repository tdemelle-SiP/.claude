# SiP Printify Manager - Mockup Update Implementation Plan

*Created: January 2025*

## Executive Summary

This document outlines the implementation plan for adding mockup update functionality to the SiP Printify Manager browser extension. The system will enable automated updating of product mockups based on template selections, addressing a critical gap in Printify's public API.

## Current State Analysis

### What Currently Works
1. **Mockup Selection in Templates**: Users can select mockups for templates via the WordPress interface
2. **Data Storage**: Selected mockups are saved in template JSON files using Printify's native `images` array format
3. **Mockup Fetching**: Extension can fetch and display blueprint mockups
4. **Extension Communication**: Established message passing between WordPress and extension
5. **Tab Management**: Extension reuses tabs efficiently with pairing system

### What's Missing
1. **Update Handler**: No `SIP_UPDATE_PRODUCT_MOCKUPS` handler in the extension
2. **DOM Interaction**: No code to manipulate mockup selections on Printify pages
3. **API Interception**: No mechanism to intercept mockup save operations
4. **Status Reporting**: No progress feedback during mockup updates

## Implementation Phases

### Phase 1: Foundation (Week 1)

#### 1.1 Create Mockup Update Handler
**File**: `/handler-scripts/mockup-update-handler.js`

```javascript
var SiPWidget = self.SiPWidget || {};
SiPWidget.MockupUpdateHandler = (function() {
    'use strict';
    
    const debug = {
        log: (...args) => console.log('♀️ [Mockup Update]', ...args),
        error: (...args) => console.error('♀️ [Mockup Update]', ...args)
    };
    
    async function handle(request, sender, sendResponse, router) {
        try {
            const { productId, shopId, blueprintId, selectedMockups } = request.data;
            
            // Navigate to mockup library
            const mockupUrl = `https://printify.com/app/mockup-library/shops/${shopId}/products/${productId}`;
            const navResult = await router.navigateTab(mockupUrl, 'printify', sender.tab?.id);
            
            if (!navResult.success) {
                throw new Error(navResult.error);
            }
            
            // Wait for page load and update mockups
            const result = await updateMockups(navResult.data.tabId, selectedMockups, router);
            
            sendResponse(result);
        } catch (error) {
            sendResponse({
                success: false,
                error: error.message,
                code: 'UPDATE_FAILED'
            });
        }
    }
    
    return { handle };
})();
```

#### 1.2 Register Handler in Router
**File**: `/handler-scripts/printify-data-handler.js`

Add new action handler:
```javascript
const asyncHandlers = {
    'updateStatus': () => handleUpdateStatus(request, router),
    'SIP_UPDATE_PRODUCT_MOCKUPS': () => handleUpdateMockups(request, router)
};

async function handleUpdateMockups(request, router) {
    if (SiPWidget.MockupUpdateHandler) {
        return new Promise((resolve) => {
            SiPWidget.MockupUpdateHandler.handle(
                request,
                {},  // sender
                resolve,
                router
            );
        });
    }
    throw new Error('MockupUpdateHandler not available');
}
```

#### 1.3 Add Handler to Background Script
**File**: `/background.js`

```javascript
importScripts(
    'core-scripts/widget-error.js',
    'handler-scripts/mockup-fetch-handler.js',
    'handler-scripts/mockup-update-handler.js',  // Add this
    'handler-scripts/widget-data-handler.js',
    'handler-scripts/printify-data-handler.js',
    'handler-scripts/wordpress-handler.js',
    'handler-scripts/printify-api-interceptor-handler.js',
    'core-scripts/widget-router.js'
);
```

### Phase 2: Page Interaction (Week 1-2)

#### 2.1 Create Content Script for Mockup Pages
**File**: `/action-scripts/mockup-library-actions.js`

```javascript
(function() {
    'use strict';
    
    const debug = {
        log: (...args) => console.log('♀️ [Mockup Library]', ...args)
    };
    
    // Listen for update commands
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (message.action === 'UPDATE_MOCKUP_SELECTIONS') {
            updateSelections(message.data)
                .then(sendResponse)
                .catch(error => sendResponse({ 
                    success: false, 
                    error: error.message 
                }));
            return true;
        }
    });
    
    async function updateSelections(selectedMockups) {
        // Wait for React components to load
        await waitForElement('[data-testid="mockup-item"]');
        
        // Get current selections
        const currentSelections = getCurrentSelections();
        
        // Update checkboxes
        const changes = updateCheckboxes(selectedMockups, currentSelections);
        
        // Trigger save
        await triggerSave();
        
        return {
            success: true,
            changes: changes
        };
    }
})();
```

#### 2.2 Add Content Script to Manifest
**File**: `/manifest.json`

```json
{
    "matches": ["https://printify.com/app/mockup-library/*"],
    "js": [
        "core-scripts/widget-debug.js",
        "action-scripts/mockup-library-actions.js"
    ],
    "run_at": "document_end"
}
```

### Phase 3: API Interception (Week 2)

#### 3.1 Enhance API Interceptor
**File**: `/action-scripts/printify-api-interceptor-actions.js`

Add mockup save detection:
```javascript
// Existing interception setup...

// Add mockup save pattern
if (url.includes('/selected-mockups') && init?.method === 'PUT') {
    debug.log('Mockup save detected:', url);
    
    // Store the request for verification
    window.sipLastMockupSave = {
        url: url,
        body: init.body,
        timestamp: Date.now()
    };
}
```

#### 3.2 Create Save Verification
**File**: `/handler-scripts/mockup-update-handler.js`

```javascript
async function waitForSaveConfirmation(tabId, router, timeout = 30000) {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeout) {
        const result = await router.sendTabMessage(tabId, {
            action: 'CHECK_SAVE_STATUS'
        });
        
        if (result.success && result.data.saved) {
            return { success: true };
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    throw new Error('Save confirmation timeout');
}
```

### Phase 4: Testing Infrastructure (Week 2-3)

#### 4.1 Add Test Mode
**File**: `/handler-scripts/mockup-update-handler.js`

```javascript
const TEST_MODE = false;  // Set via storage or config

async function updateMockups(tabId, selectedMockups, router) {
    if (TEST_MODE) {
        debug.log('TEST MODE: Would update mockups:', selectedMockups);
        return { 
            success: true, 
            testMode: true,
            wouldUpdate: selectedMockups 
        };
    }
    
    // Real implementation...
}
```

#### 4.2 Create Debug UI
**File**: `/action-scripts/mockup-library-actions.js`

```javascript
function createDebugOverlay() {
    const overlay = document.createElement('div');
    overlay.id = 'sip-mockup-debug';
    overlay.style.cssText = `
        position: fixed;
        top: 10px;
        right: 10px;
        background: rgba(0,0,0,0.8);
        color: white;
        padding: 10px;
        z-index: 9999;
        font-family: monospace;
        max-width: 400px;
    `;
    document.body.appendChild(overlay);
    return overlay;
}

function logDebug(message, data) {
    if (!window.sipDebugMode) return;
    
    const overlay = document.getElementById('sip-mockup-debug') || createDebugOverlay();
    overlay.innerHTML += `<div>${new Date().toISOString()}: ${message}</div>`;
    if (data) {
        overlay.innerHTML += `<pre>${JSON.stringify(data, null, 2)}</pre>`;
    }
}
```

### Phase 5: Error Handling & Recovery (Week 3)

#### 5.1 Implement Retry Logic
```javascript
async function updateMockupsWithRetry(tabId, selectedMockups, router, maxRetries = 3) {
    let lastError;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const result = await updateMockups(tabId, selectedMockups, router);
            return result;
        } catch (error) {
            lastError = error;
            debug.log(`Attempt ${attempt} failed:`, error.message);
            
            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
            }
        }
    }
    
    throw lastError;
}
```

#### 5.2 Add Progress Reporting
```javascript
async function reportProgress(step, progress, message) {
    await chrome.storage.local.set({
        sipMockupUpdateProgress: {
            step: step,
            progress: progress,
            message: message,
            timestamp: Date.now()
        }
    });
}
```

## Integration Points

### WordPress Side Updates

#### 1. Update Message Sending
**File**: `template-actions.js`

```javascript
function updateProductMockupsViaExtension(product, selectedMockups, blueprintId, dialog) {
    return new Promise((resolve, reject) => {
        chrome.runtime.sendMessage(extensionId, {
            type: 'wordpress',
            action: 'SIP_UPDATE_PRODUCT_MOCKUPS',
            data: {
                productId: product.printify_product_id,
                shopId: window.sipPrintifyManagerData.shopId,
                blueprintId: blueprintId,
                selectedMockups: formatMockupsForExtension(selectedMockups)
            }
        }, function(response) {
            if (response && response.success) {
                resolve(response);
            } else {
                reject(new Error(response?.error || 'Unknown error'));
            }
        });
    });
}
```

#### 2. Add Mockup Formatting
```javascript
function formatMockupsForExtension(templateImages) {
    // Convert template images array to extension format
    return templateImages.map(image => {
        const mockupId = extractMockupIdFromUrl(image.src);
        return {
            id: mockupId,
            variant_ids: image.variant_ids,
            is_default: image.is_default
        };
    });
}
```

## Testing Plan

### Manual Testing Checklist
1. **Single Product Update**
   - [ ] Navigate to mockup library successfully
   - [ ] Current selections detected correctly
   - [ ] Checkboxes update visually
   - [ ] Save triggers automatically
   - [ ] Success reported to WordPress

2. **Batch Updates**
   - [ ] Multiple products process sequentially
   - [ ] Tab reuse works correctly
   - [ ] Progress updates shown
   - [ ] Failures don't stop batch
   - [ ] Summary accurate

3. **Error Scenarios**
   - [ ] Network timeout handled
   - [ ] Invalid product ID rejected
   - [ ] Missing mockups logged
   - [ ] Save failures reported
   - [ ] Retry logic works

### Automated Testing
```javascript
// Test suite for mockup updates
describe('Mockup Update Handler', () => {
    it('should navigate to correct URL', async () => {
        const result = await handler.handle({
            data: {
                productId: 'test123',
                shopId: 'shop456',
                selectedMockups: []
            }
        });
        
        expect(navigatedUrl).toBe('https://printify.com/app/mockup-library/shops/shop456/products/test123');
    });
});
```

## Rollout Strategy

### Stage 1: Alpha Testing (Week 4)
- Deploy to development environment only
- Test with single products
- Verify no interference with existing features
- Collect detailed logs

### Stage 2: Beta Testing (Week 5)
- Enable for select users
- Test with small batches (5-10 products)
- Monitor performance metrics
- Gather user feedback

### Stage 3: Production Release (Week 6)
- Full release with feature flag
- Documentation updates
- Support team training
- Monitor error rates

## Success Metrics

### Technical Metrics
- **Success Rate**: >95% of mockup updates complete successfully
- **Performance**: Average update time <5 seconds per product
- **Reliability**: <1% timeout rate
- **Error Recovery**: 90% of failures recover on retry

### Business Metrics
- **Time Saved**: 90% reduction in manual mockup management time
- **User Adoption**: 80% of users with templates use mockup updates
- **Support Tickets**: <5% increase in extension-related support

## Risk Mitigation

### Technical Risks
1. **Printify UI Changes**
   - Mitigation: Use multiple selectors, API-first approach
   - Fallback: Manual update instructions

2. **Rate Limiting**
   - Mitigation: Implement throttling, respect API limits
   - Fallback: Smaller batch sizes

3. **Extension Conflicts**
   - Mitigation: Namespace all code, minimal DOM manipulation
   - Fallback: Dedicated profile recommendation

### Business Risks
1. **Data Loss**
   - Mitigation: Never delete, only update
   - Fallback: Backup current selections first

2. **User Confusion**
   - Mitigation: Clear progress indicators, detailed logs
   - Fallback: Manual recovery guide

## Documentation Requirements

### User Documentation
1. **Setup Guide**: How to enable mockup updates
2. **Usage Tutorial**: Step-by-step mockup selection
3. **Troubleshooting**: Common issues and solutions
4. **FAQ**: Anticipated questions

### Developer Documentation
1. **Architecture Overview**: System design and data flow
2. **API Reference**: Message formats and responses
3. **Testing Guide**: How to test locally
4. **Debugging Guide**: Tools and techniques

## Timeline Summary

| Week | Phase | Deliverables |
|------|-------|--------------|
| 1 | Foundation | Basic handler, router integration |
| 1-2 | Page Interaction | Content scripts, DOM manipulation |
| 2 | API Interception | Save detection, verification |
| 2-3 | Testing Infrastructure | Test mode, debug UI |
| 3 | Error Handling | Retry logic, progress reporting |
| 4 | Alpha Testing | Internal testing, bug fixes |
| 5 | Beta Testing | Limited release, feedback |
| 6 | Production | Full release, monitoring |

## Next Steps

1. **Immediate Actions**
   - Create `mockup-update-handler.js` file
   - Add handler registration to router
   - Set up development test environment

2. **This Week**
   - Implement basic navigation and page detection
   - Create debug logging infrastructure
   - Test single product update flow

3. **Next Week**
   - Add DOM manipulation logic
   - Implement save verification
   - Begin integration testing

## Conclusion

This implementation plan provides a structured approach to adding mockup update functionality to the SiP Printify Manager extension. By following this phased approach, we can deliver a reliable, user-friendly solution that addresses a critical gap in Printify's API while maintaining code quality and system stability.