Distribution of Mermaid Diagrams in v2

  1. Master System Architecture (Section 2.1)

  What it shows: The complete extension architecture with all
  components, their functions, and communication paths at a
  consistent level of detail.

  Key elements:
  - All files and their main functions
  - Message flow paths (postMessage, chrome.runtime,
  chrome.storage)
  - Storage components with actual keys
  - Chrome API interactions

  Relation to master: This IS the master diagram - all others
  expand specific parts of this.

  Standalone use: When you need to understand:
  - How a message gets from WordPress to a handler
  - Which file contains which functionality
  - The overall system structure
  - Where to add new components

  ---
  2. Complete Message Flow (Function Level) (Section 2.2)

  What it shows: Detailed sequence of function calls for a complete     
   operation (mockup update example).

  Key elements:
  - Every function call in order
  - Success, error, and timeout paths
  - Exact parameters passed
  - Activation lifetimes

  Relation to master: Expands the message path arrows from master       
  diagram into step-by-step function calls.

  Standalone use: When you need to:
  - Debug why a message isn't reaching its destination
  - Understand the exact call sequence
  - Add logging at specific points
  - Trace timeout issues

  ---
  3. Storage Architecture Detail (Function Level) (Section 2.3)

  What it shows: All functions that interact with Chrome storage        
  and their relationships.

  Key elements:
  - Every storage read/write function
  - Cache relationships
  - Storage key organization
  - onChange event flows

  Relation to master: Expands the Storage boxes and dotted arrows       
  from master into specific function interactions.

  Standalone use: When you need to:
  - Add new storage keys
  - Debug storage-related issues
  - Understand caching strategy
  - Trace state management

  ---
  4. Tab Pairing System Detail (Function Level) (Section 2.4)

  What it shows: Complete flow from user click to bidirectional tab     
   pair creation.

  Key elements:
  - User interaction through to storage
  - All decision branches (paired exists, tab closed, same URL)
  - Bidirectional storage pattern
  - Function parameters

  Relation to master: Expands the navigateTab() function and
  tabPairs storage from master.

  Standalone use: When you need to:
  - Debug "Go to Printify" navigation issues
  - Understand tab reuse logic
  - Implement similar pairing features
  - Fix tab relationship problems

  ---
  5. Extension Detection & Installation Flow (Function Level) 
  (Section 5.1)

  What it shows: How the extension announces itself after
  installation.

  Key elements:
  - chrome.runtime.onInstalled handling
  - Script injection sequence
  - Conditional announcement logic
  - Fresh detection pattern

  Relation to master: Expands extension-detector.js and its
  announcement flow from master.

  Standalone use: When you need to:
  - Debug "extension not detected" issues
  - Understand installation flow
  - Implement detection on new pages
  - Fix announcement timing

  ---
  6. Message Format Transformation (Function Level) (Section 6.1)       

  What it shows: How external WordPress messages transform to
  internal format.

  Key elements:
  - Format at each stage
  - Every transformation function
  - Security validation points
  - Handler delegation

  Relation to master: Expands the Relay → Router → Handler message      
  path from master.

  Standalone use: When you need to:
  - Add new message types
  - Debug message format issues
  - Understand the relay's purpose
  - Trace command routing

  ---
  7. Tab Pairing System (Section 7.1)

  Note: This appears to be a duplicate header - the actual diagram      
  is in 2.4

  ---
  8. Pause/Resume Error Recovery (Function Level) (Section 7.2)

  What it shows: Complete error detection and recovery flow.

  Key elements:
  - Error detection functions
  - State storage for pause
  - UI update flow
  - Promise-based resume

  Relation to master: Expands pauseOperation()/resumeOperation()        
  and their storage interactions from master.

  Standalone use: When you need to:
  - Add pause/resume to new operations
  - Debug stuck operations
  - Understand error recovery
  - Implement similar patterns

  ---
  9. Response Logging Architecture (Function Level) (Section 7.3)       

  What it shows: How response logging works at infrastructure
  level.

  Key elements:
  - sendResponse wrapping
  - Log timing and content
  - Success vs error paths
  - Timeout detection

  Relation to master: Expands the Router's wrapSendResponse()
  function from master.

  Standalone use: When you need to:
  - Understand action log entries
  - Debug missing responses
  - Add similar infrastructure features
  - Trace operation outcomes

  ---
  Summary

  The diagrams follow a clear hierarchy:
  1. Master diagram - Complete system view
  2. Detail diagrams - Each expands a specific aspect from master       
  3. Function level - Shows actual implementation

  Each detail diagram is self-contained for its specific purpose        
  but explicitly references what it expands from the master,
  maintaining clear relationships throughout the documentation.