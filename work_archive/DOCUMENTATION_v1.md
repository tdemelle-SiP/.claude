# SiP Printify Manager Plugin Documentation

## Table of Contents
- [Printify Token Entry Screen (Shop Initialization)](#printify-token-entry-screen-shop-initialization)
- [Main Printify Manager Dashboard](#main-printify-manager-dashboard)
  - [Product Table](#product-table)
	- [Product Table Features](#product-table-features)
  - [Image Table](#image-table)
	- [Image Table Features](#image-table-features)
  - [Template Table](#template-table)
	- [Template Table Features](#template-table-features)
  - [Product Creation Table](#creation-table-section)
	- [Product Creation Table Features](#creation-table-section-features)
  - [Template JSON Editor](#template-json-editor)
	- [Template JSON Editor Features](#template-json-editor-features)

---

## Printify Token Entry Screen (Shop Initialization)

### Overview
The Token Entry Screen is the first screen that appears to users when they launch the SiP Printify Manager Plugin in Wordpress. This screen provides instructions and a field where users may enter their Printify API token to authorize the plugin and connect their Printify account.  If a printify token is successfully entered, the Token Entry Screen will be replaced by the main Sip Printify Manager Dashboard.

---

## Main Printify Manager Dashboard
The main dashboard is the central interface where users can manage products, images, templates, and create new products.  

After a shop is first inititialized, you'll see your shop name and a "New Shop Token" button for re-authentication or to load a new store into the manager. You will also see products and images downloaded from Printify presented on the dashboard in a series of tables.

 The SiP Printify Manager dashboard interface is divided into four main tables:

Three "source tables"
products  (top-left)- 
	populated by an API call from the users printify shop

images (right)- 
	populated in part by an API call from the users printify shop and also by uploaded images.

templates (middle-left)- 
	templates are a data form that is exclusive to the sip printify manager plugin.  Templates are the backbone of the efficient bulk new product creation process that the plugin enables.

And then the Product Creation Table at the bottom of the screen where the source tables are used to create new products.

When there is not a template loaded into the product creation table, it shows only a header, "Product Creation Table" and a block of text that explains:
To Create new products, choose a template in the Templates table, select it, choose "create new product" from the dropdown menu and click "execute".  The Product Creation Table will populate with the template data and you can editing.

### Product Table
This table displays a list of all products available in the connected Printify shop.

- Products are automatically retrieved from your shop when it is first initialized and listed in the products table in the top-left section of the interface.  Products from your shop can be easily reloaded at any time.
- The table shows Thumb (thumbnail) and Product Name for each item.

#### Product Table Features
- **Search**: Allows users to search for specific products by name or category.
- **Sorting**: Click on column headers to sort products by name, category, or date added.
- **Filtering**: Filter products by status, category, or tags.

#### Creating Templates from Products
A template must be created from an existing product in the products table in order to use the Product Creation Table.

Once a template is available in the template table, the new product table can be opened by selecting it and choosing "create new product" from the pulldown menu.

1. Select one or more products from the list by checking the boxes next to them.
2. Choose "Create Template" from the dropdown menu above the product list.
3. Click "Execute" to create templates based on the selected products.

### Image Table
The image table contains all images available for use in product templates and designs.

- Images are also automatically retrieved from your shop and displayed in a table in the top-right section of the interface.
- The table shows Thumb, Filename, Location, Uploaded date, Dimensions, and Size for each image.

#### Image Table Features
- **Bulk Actions**: Select multiple images to delete, categorize, or tag.
- **Upload New Images**: Allows users to upload additional images to the table for use in templates.
- **Search and Filter**: Search by image name, category, or tag to quickly locate specific assets.

#### Uploading Images

- To add new images to use to create new products, drag and drop images into the designated area at the top of the Images section.
- Alternatively, click the "Select Images" button to choose files from your computer.

#### Adding Images to New Products

1. Once you have a template loaded into the Product Creation Table, choose a column corresponding to an image in a print area, select one or more images from the list.
2. Choose "Add to New Product" from the dropdown menu above the image list.
3. Click "Execute" to use these images in the Product Creation Table.
   You can also select individual cells in the table to add a single image to multiple cells at once.

#### Initial Image Design
There are two categories of images, local images and remote images.  
##### remote images 
are images downloaded from your printify shop when you first initialize it by entering your printify token  They are automatically loaded into the plugin's images table.  Remote images can be easily reloaded into the images table at any time by selecting and executing the reload images option from the pulldown at the top of the images table.

##### Local images 
are images that are in a local or cloud directory (google drive) that have been loaded into the image table directly from the users SiP Printify Manager Dashboard.  

In the images column, There is a title that says "Images". Under it is the action dropdown with an execute button next to it just like the products ui. under that is the table which displays the images and under that is a drag and drop target area with an import button in it for loading local images into the table.

The actions available for the images in the images action pulldown which mirrors the product actions pulldown should include: 
*"reload shop images"
*"remove from manager" (removes from plugin database)
*"add to new product" (populates the selected field in the create product table)
*"upload to shop"
*"archive shop image"

Each image row element includes:
*a checkbox toggle on the left side of each to select the target for the action pulldown.  

*a small thumbnail

*the filename

*location (remote, remote (archived), or local). image archive functionality has been removed form the code since this was written
	-remote image designation means the images is in the printify database and is assigned when the image is added to the manager database through the printify API call.  Local images are updated to Remote when a local image has been uploaded using the API through a manager action.
	-local image designation is assigned when an image is opened from google drive or another local drive.

*uploaded (this should only be populated for images in the remote location)
	-derived from the "upload_time": "2020-01-09 07:29:43" property.  Should appear in the format "20_01_09 07:29".

^dimensions (WxH)
	-derived from "height", "width" properties in the case of remote images.
	-derived in some logical and efficient way from the google drive data for local images.

*size (in kB or in MB for files of 1MB or above)
	-derived from "size" property in the case of remote images.
	-derived in some logical and efficient way from the google drive data for local images.

### The Template
When a template is first created from a product, the following data is pulled directly from the selected source products json file and stored as a new template file that becomes available in the template table list.   

Here's the template data framework

{
	"template title": (Product Title) Template 
	"source product": Product Title
	"source product id":
	"template id": (template_title)_0001
	"description":
	"tags": [],
	"variants": [
	    {
		"id":
		"price":
		"is_enabled":
		"options": [
			(color),
			(size)
		]	
	    },
	    {
		"id":
		"price":
		"is_enabled":
		"options": [
			(color),
			(size)
		]	
	    },
	    etc...
	],
	"blueprint_id":
	"print_provider_id":
	"print_areas": [
	    {
		"variant_ids": [
		],
		"placeholders": [
			"position":
			"images": [
				{
					"id":
					"name":
					"type":
					"height":
					"width":
					"x":
					"y":
					"scale":
					"angle":
					"src":
				},
				{
					"id":
					"name":
					"type":
					"height":
					"width":
					"x":
					"y":
					"scale":
					"angle":
					"src":
				},	
				etc...
			]
	    },
	    {
		"variant_ids": [
		],
		"placeholders": [
			etc...
	],
	"source product":
	"source product id":
	"options - colors": [
	    {
		"id":
		"title":
		"colors": [
			(#colorhex)
		]
	    },
	    etc...
	],
	"options - sizes": [
	    {
		"id":
		"title":
	    },
	    etc...
	]

}

//the following data structures are added 

"template title": (Product Title) Template 
"source product": Product Title
"source product id":
"template id": (template_title)_0001

Each new template created from a source product is incremented.  This data is stored in the sip-database

//after work has been done and saved in the Product Creation Table

//these top level categories, creations, work in progress, archived, in addition to "new", are options that appear in the "states" column in the Product Creation Table

The arrays and keys in each of these categories should reflect the data that has been edited in the Product Creation Table

new			//the default product state when a new product row is created


"creations": [	//products that have been created using the printify create product API
	"template title": [
		"tags": []
		"description":
		"price":
		"sizes":
		"colors":
		"print-area":
			image#

work in progress	//products that have been modified in the table and saved, but not created
	title
		tags
		description
		price
		sizes
		colors
		print-area
			image#

archived		//products that have been archived (locally)
	title
		tags
		description
		price
		sizes
		colors
		print-area
			image#	


	When the user selects a template in the template table and chooses "create new product" from the pulldown, 
		the product creation table appears and is populated with the template data as described in more detail below
		The images table list is updated to show which images the template has used to create new products 
			-row backgrounds of images in the images table with ids that are in products in the created state are colored light green.  
			-row backgrounds of images in the images table with ids that appear in work in progress products are colored light yellow
			-row backgrounds of images in the images table that have been added to the product creation table in the current session but are not yet saved, products in the "new" state, are light blue

		((metadata shows up in a template data window above the product creation table
			-number of product variants made
			-number of colors
			-number of sizes
			-number of variant permutations
			-list of print-areas
			-eventually blueprint info, printer info))

### Template Table
The template table displays available templates that can be used to create new Printify products.  

After the user has created a template from the product table by selecting a product and executing 'Create Template', the template becomes available in the template table.
Individual templates in the template table can be loaded one at a time into the Product Creation Table by selecting them in the template table and executing Create New Product.

Templates are displayed in the template table with the following data columns:
checkbox | Template Name | Creations | WiP
	checkbox is used to select the template as the target for actions in the template action pulldown.

	Template name - shows the template name

	Creations - shows the number of products that have been created from the template

	WiP - shows the number of products that have been started but not yet completed

The actions in the template table action pulldown consiste of the following:

create new product - 
	When the user selects a template in the template table and chooses "create new product" from the pulldown, 
		the product creation table appears and is populated with the template data as described in more detail below
		The images table list is updated to show which images the template has used to create new products 
			-row backgrounds of images in the images table with ids that appear in published products are colored light green.  
			-row backgrounds of images in the images table with ids that appear in work in progress products are colored light yellow
			-row backgrounds of images in the images table that have been added to the product creation table in the current session are light blue
			((the table should be filterable by these categories - perhaps this is something that can be added to the table footer))
		((metadata shows up in a template data window above the product creation table
			-number of product variants made
			-number of colors
			-number of sizes
			-number of variant permutations
			-list of print-areas
			-eventually blueprint info, printer info))

archive template -
	if a template is archived from the template table ((still need to add archive template pulldown option)), the source json template file is moved to an archive folder in the templates folder in local storage.  if the template being archived is active in the product creation table, the table is closed after checking to see if the user wants to save any changes that may have been made.  ((Need to add some kind of type filter to the table.   Perhaps on the table footer?  And then that convention can be used to filter out published products in the create product table as well.))

delete template -
	delete template option should be ((safeguarded with alerts)).  templates contain irreplaceable plugin data and should not be accidentally deleted.

#### Template Table Features
##### Creating New Products from Templates

###### Select a template from the list by checking the box next to it.
###### Choose "Create New Products" from the dropdown menu above the template list.
###### Click "Execute" to load the template into the Product Creation Table.
   The structure of the template product will appear in the first row of the Product Creation Table and the source content from the template will populate the second row.
#### Duplicate and Delete Templates**: Options for duplicating or deleting templates are available in the actions column.

### Product Creation Table

The Product Creation Table allows users to view templates and use them to createe new Printify products.

When a template is selected for creating new products, the full product creation table, located at the bottom of the dashboard, appears consisting of two main parts, the header and the table itself.  Once a template has been opened in the product creation table, it persists through browser refreshes and sessions and will remain open until closed or replaced by another template.

The product creation table enables the use of a product template as the starting point for easily establishing new variants of the source product that can then be used to easily create new Printify products.

When a template is loaded into the product creation table, a copy of the source template is created that tracks the changes made in the product creation table in realtime. This copy of the template.json is named the same as the source template appended with '_wip' and is stored in a /wip/ directory.  The wip file persists as long as the template is open in the product creation table including across page reloads and sessions.

When the page is reloaded, a check is made to confirm whether there was a template loaded in the product creation table by checking to see if there is a wip file.  If there is a wip file, its contents are loaded into the product creation table.

When changes are made in the product creation table, the file is flagged as having unsaved changes (all changes made in the product creation table are reflected in the wip file in near realtime) and the save button styling is updated to indicate there are unsaved changes.  Having unsaved changes means that the _wip file is different than the source file.

Pressing 'save' in the product creation table updates the source template file with the data in the wip template file, resets the flag indicating unsaved changes and reverts the save button to its default state.

If the 'close' button is pressed when a template is loaded with unsaved changes, an option window pops up allowing the user to choose between
	-save and close - saves the changes in the wip file to the source file, deletes the wip file and unloads the loaded template from the product creation table
	-discard and close - discards the changes in the wip file, deletes the wip file and unloads the loaded template from the product creation table
	-cancel - closes the option window leaving the loaded template and its unsaved changes stored in the wip file in place

If a template in the template table is selected and the Create New Products action is executed, if there is a template already loaded with unsaved changes, the user will be presented with an option window with the following options
	-save changes - saves the currently loaded wip template to its source template json file, closes that template and opens the new template
	-discard changes - discards the currently loaded wip template, closes that template and opens the new template
	-cancel - dismisses the option window making no changes


#### Product Creation Table Features
##### Product Creation Table Header
 The header area of the product creation table includes the "product creation table" masthead under which a subtitle appears that shows the name of the currently selected template.  To the left and right of these centered titles in the header, there are buttons and controls for interacting with the loaded template data and building new products. 

The current slate of Product Creation Table header controls includes:

	edit template json button - The edit json button brings up the existing template editor overlay.  This already exists.  The code to bring it up is in the templateEditor.js file

	save button - The save button saves changes reflected in the table to the template.json.  The table remains open for continued editing.

	close button - The close button removes the selected template from the table.  If there are unsaved changes it prompts whether the user would like to save before closing.

	publish products button - assembles the selected rows into json files that are submitted to printify through its api
			
	actions pulldown - actions that will be applied to selected cells, rows or columns.
		- reset to template
		- clear selection

	import csv button - The import csv button brings up a file upload dialog that allows the user to upload a csv file that will populate the table with new products.  The csv file should be structured in the same way as the template json file.

	export csv button - The export csv button saves the current table data to a csv file that can be downloaded by the user.

##### Product Creation Table Table
The product creation table table appears below the product creation table header.  The product creation table header row is created dynamically when a template is loaded into the product creation table based on the data content of the loaded template.

The first time a template is loaded into the product creation table it will show a dynamically generated header row and a template summary row reflecting the data in the loaded template file.  The template summary row has a toggle on the far lest side that can be clicked to show and hide whatever variants there may be in the source template data in individual template-variant rows.

Below the Product Summary Row is the "Add new Product" Row which is a blank row that can be used to create copies of the template data that can be used to create new products.

The "Add New Product" Row will have a + sign button in the far left cell and a row type of "Add New Product".  The rest of the cells in the row will be blank. When the + sign button is clicked, it turns the Add New Product row into a Template-Copy row.

The Template Copy row represents a copy of the template data that can be edited to create new variants of the product described in the template file.  When first created, it is an exact copy of the source template data but with a title generated from the source template title appended with an incrementing number _00001.  This number should be permanently stored in a second "template-copy" key in addition to the title so that the title can be changed in the editor, but each time a new product is made, the number can be incremented based on the total number of products that have been made (and not deleted) regardless of name. 


Once changes have been made to the data in a template-copy row, the row type will be updated to "WiP" indicating it is work in progress.  The work in progress designation will remain until the product is published to Printify at which time the product row type will be updated to "Published".

If changes are made to a Published product, the row type will be updated to "Published - WiP".

All Template - Copy, WiP, Published and Published-WiP rows can be saved to the source template file and appear in the table whenever it is reloaded.



##### Table Columns
###### HEADER ROW
The first row of the table consists of table header cells populated dynamically by the keys from the loaded template arrrays.The typical compliment will include the following:

| checkbox | Row Type | # | Title | design - front | colors | sizes | tags | description | price | design - printlocation A | design - printlocation etc |

###### TEMPLATE SUMMARY ROW
The second row of the table is the template summary row and is populated with data that reflects the full content of the template.json file including all the varaiants of the source product that it describees

There is a toggle on the left side of the template summary row that can be clicked to show the individual variants and their specific data in individual template-variant rows.






- **Customization Options**: Modify product details like price, category, and tags before creating the product.
- **Bulk Creation**: Allows users to create multiple products at once using different variations of a template.

##### Editing Product Details

- Click on cells in the table to edit the corresponding information for each product.


### Template JSON Editor
The Template JSON Editor is an advanced tool for editing JSON configurations of templates directly.

After the user has loaded a template into the Product Creation Table (creating a template_wip file that tracks changes made in the product creation table), one of the available options for editing the template is the "Template JSON Editor".  This is accessible through the Edit JSON button.

When the edit json button is clicked
	an editor-state.json file is created in the wip folder from the wip file that's tracking the changes in the product creation editor.
	the editor-state.json is opened in the template json editor
		the loaded template title is put into the header
		the data is separated out into the description and the rest of the json and each is loaded into its respective editor in the template json editor.
		  The editor-state.json file tracks the state of the json editor while it is open. The editor-state file should be updated with every change to the template json editor in realtime.  When a change is made, there should be a jsonEditorIsDirty state tracker indicating there are changes in the editor

If the browser is reloaded, upon load, if there is an editor-state.json file, the editor should be opened, the data in the file restored into the editor which should include all changes that have been made in the editor. The jsonEditorIsDirty state should be preserved from the state on reload and the listener that saves edits in realtime to the editor-state.json should be re-initialized.

There's a button in the template editor called "push changes to product creation table".  Clicking this button will save the changes in the editor-state.json to the template_wip.json file and reset the jsonEditorIsDirty state to false.  The template editor will remain open and the listener that updates the editor-state.json must be re-initialized if necessary.  as soon as new changes are made, the jsonEditorIsDirty state should be set to True.

When the editor is closed by using the close button
	-if there are unkept changes, a window should come up giving the user the options
		-Push and Close - the spinner appears, changes in editor-state.json are pushed to the wip file, the editor-state.json is deleted and the product creation table is updated to reflect the updated changes now in the wip file.  Then the options window and template json editor are both closed. Then the spinner is hidden.
		-Discard and Close - the spinner appears, the editor-state.json is deleted, the options window and the template editor are closed. the spinner is hidden
		-cancel - the options window is closed.  the editor-state.json is kept.  The user may continue editing in the template json editor.

#### Template JSON Editor Features
- **Syntax Highlighting**: The editor provides syntax highlighting for JSON to improve readability.
- **Validation**: Checks JSON syntax for errors before saving.
- **Preview Changes**: View changes made to the template in real-time.
- **Autosave**: Automatically saves changes periodically to prevent data loss.

#### JSON Editor Code Flow
Function jsonEditorOpen()
when the editor is opened
	-the editor-state.json is created as a copy of the current _wip.json file
	-the editor modal opens and the editor-state.json is processed separating the description from the rest of the json.
    -the title is loaded into the header 
    -The two windows in the modal are populated with the appropriate editor-state.json data.

Function jsonEditorModal()
    -set up container window
    -two editor windows - scroll
    -buttons - push, close
    -move, resize, editor window sliders
    -html toggle
    -description and json search functionality
    -html and json linters

Function jsonEditorEdit()
    when edits are made in either editor:
    the jsonEditorIsDirty state is toggled to yes
    the editor-state.json is updated in realtime.

Function jsonEditorPushChanges()
    if the push changes to creation table button is pressed
    any changes that have been made in the editor-state.json are copied to the _wip.json file
    the jsonEditorIsDirty state is toggled to no.

jsonEditorReload()
    If the page is reloaded
    If there is an editor-state.json file
    the editor is opened and populated with the content of the editor-state.json file. 
    If no editor-state.json is present, the editor is not loaded.

jsonEditorClose()
    if the close button of the template json editor is clicked, 
    if the jsonEditorIsDirty is no, the template json editor closes.  
    If the jsonEditorIsDirty is yes, a window pops up giving the user three options:
        keep and close: saves the contents of the editor-state.json to the template_wip.json, resets the has changes to false, deletes the template-state.json, closes the window and closes the editor modal.
        discard and close: deletes the editor-state.json, sets the has changes to false, closes the window and closes the editor.
        cancel - closes the window.


---

## Additional Resources

- **FAQs**
- **Troubleshooting Tips**
- **Contact Support**

---------------------------------THE CODEBASE FILE STRUCTURE---------------------------------


---------------------------------
This codebase should implement state management following these principles:
DATA LIFECYCLE:

LOAD: Initial data loading from JSON/storage
RELOAD: Data updates after AJAX
TRACK: Real-time UI state changes
REFRESH: State restoration after reload/AJAX

UI State:
Stored in localStorage
Tracked in real-time by individual modules
Refreshed by utilities.js after AJAX/reload


Data:
Stored in JSON files
Loaded/reloaded by individual modules
Manipulated through AJAX calls

IMPLEMENTATION PATTERN:
Individual JS files should:

Handle their own real-time UI updates
Save state to localStorage
Load/reload their data
ui state refresh code should be removed (moves to utilities.js)

utilities.js handles:

Dashboard-wide state refresh after AJAX/reload
Cross-component state coordination

ajax.js ensures:
Success handlers process data first
utilities.refreshDashboard() runs after

The current goal is to review individual JS files against this pattern, identifying code that should:
Move to utilities.js
Be refactored for localStorage
Be removed as redundant
Be retained for data/realtime UI handling
---------------------------------

additional summary of the intended logic for data and state lifecycles... we have these events for stored data:
LOAD
RELOAD
TRACK
REFRESH

on page load,
	Main.js initializes
	↓
	Individual js init functions builds relevant interface as necessary, tracks DATA changes and ui state changes.
	↓ 
	Utilities.js REFRESHes UI state (if none saved, it refreshes defaults) on page load and after all ajax call successes
	It's not cleanly and clearly set up this way at the moment, but I'm thinking perhaps Utilities.js could also LOAD and RELOAD Data on page load and after all ajax call successes - so the pattern would be, individual.js files create the front end and track changes to data and ui state and then on reload and ajax success utilities.js RELOADS data and REFRESHES ui state.

on interaction,
individual.js files TRACK (which includes front end refresh) realtime ui state changes
    ui state is saved in localStorage

Individual js file listeners respond to data edits by triggering action functions that send those changes to be handled by PHP functions
    These send AJAX calls to corresponding individual PHP files. 
 
Individual php files perform server side functions.
    These write to and read from json files and then trigger success response.
		Success response is sent back to the originating .js file but not sure there's much for the originating js file to do with it.
	Ajax.js responds to each success response by triggering the RELOAD/REFRESH function in utilities.json
		
	Utilities.js reloads data and ui state.  (I suppose I'm not certain about whether/how the response data from the php file makes its way to the utilities.js file for the reload... or if it even needs that if its just reloading from a known data source depending on what's open on the page?)

Utilities.js REFRESHes ui state restored from localStorage

-----------------------------------
shop - handles listeners and actions on the token entry page
product - handles listeners and actions in the product table
image - handles listeners and actions in the image table
template - handles listeners and actions in the template table

creation-table - if a template is loaded, handles listeners and actions in the product creation table
json-editor - if the json-editor is open, handles listeners and actions in the json-editor
catalog-image-index - if a template is loaded, handles listeners and actions from the catalog-image-index

=========================================JAVASCRIPT FILE FUNCTIONAL OVERVIEW=================================================
js files perform the following functions within the scope of particular segments of the ui
	-build and load their particular interface
	-attach listeners to their interface ui elements
	-save ui state changes into localStorage
	-pass edits to any data loaded in their interface to appropriate .json file

specific js file		|  ui segment		| data handled
-----------------------------------------------------------------------------------------
catalog-image-index-actions.js 	|  image index table 	| this is a viewer not an editor
image-actions.js		|  image table		| viewer for printify shop images / manager for local file data (not sure how this is stored)
json-editor-actions.js		|  json editor		| editor-state.json
product-actions.js		|  product table	| this is a viewer not an editor
shop-actions.js			|  main dashboard	| this is a viewer not an editor
template-actions.js		|  template table	| template.json files
creation-table-setup-actions.js	|  creation table	| this is a setup file not an editor
creation-table-actions.js	|  creation table	| template_wip.json file

main.js	- initializes other js files. performs initial load sequence - calls on utilities.js to load data and refresh ui state.
utilities.js - reloads ui state and data on load and reload - other utility functions
ajax.js - handles ajax - calls utilities to refresh ui state and reload data on ajax call success

**creation-table-setup-actions builds the product creation table based on the template.json file that is loaded.  The table is built dynamically based on the data in the particular template file, so creation-table-setup-actions needs to get the template data and then build the table based on what's in there.  When it's done, utilities.js can reload the data and refresh the ui state. 

====================================================================================================

-----------------------------------------UI STATE REFRESH VS DATA UPDATE LOAD-----------------------------------------------

there's a difference between ui state and data management.   ui state is stored in localStorage and includes things like checkboxes, scrollbars, sort order, visibility toggles.  Data being saved and loaded in the operation of the plugin is generally handled in json files.  The terms track and refresh are used for function names for ui state and the terms SAVE, LOAD and RELOAD for data functions.  I tend to use STATE in reference to the ui state.  and DATA UPDATES would be the counterpart in terms of data?  So we LOAD, EDIT, SAVE DATA UPDATES and REFRESH and TRACK UI STATE.  There is a third category of data processing that functions perform and that is summarizing data presented to the user in response to data updates; the functions that perform these actions should use the term UPDATE ... so counts are updated after data is changed or loaded.

I am inclined to have utilities update Data state at least on ajax success call.  This way I can just lump data reload in with ui state refresh in one place in all those cases and save myself having to repeat data load code in multiple places.  so for Data...
main.js runs through the specific js files init functions and they each create their ui elements and have data loaded on initialization on page load.  Once loaded, during user interaction, the specific js files track ui state for their ui elements listeners and send ajax calls to their partner php files to update the data that they are tracking as its edited by the user.  When those ajax calls successes are returned, ajax.js passes the relevant data to utilities.js and utilities.js updates data and refreshes ui state from localStorage all together after ajax calls.  This way when something is updated in the creation table that would affect highlights and states in the image table, it can all be handled together through the utilities function.  I'm not 100% sure how to handle data load/reload between main.js on initialization which then calls utilities.js to update ui state and utilities.js by itself on ajax success when I think it would make sense for it to update both data and refresh ui state.  This seems to be directly related to the issue that we're trying to address with the table loading correctly on page load, but not correctly as the result of an ajax call.  Main.js is calling the correct refresh function as part of initialization that loads the table, but that's not happening when the main.js initialization is bypassed and utiltities.js is updating by itself.  The natural response seems to me to be to move data reload to utilities.js along with state refresh and have it do both for page load/reload AND ajax success.


-------------------------------------------------Image Table Visibility Logic--------------------------------------

When the header checkbox is clicked, whatever the selection state of visible rows should be inverted.  if its clicked again, visible rows should be deselected. It should then alternate between inverted selection and deselection.  If there are checkboxes in rows manually selected, that should reset the behavior of the header toggle so that the next click is an inversion.  So you could do something like...

click three rows to select them, invert and all but those three are selected, deselect two of those and select one of the previously deselected ones and the next click on the header selector will invert that selection.  It is only when the header is toggle twice in a row that it triggers a deselection.

invisible rows should not be selected when a parent row is selected.  If a selected row's visibility is disabled, it should become unselected.  There should be no circumstance in which an action is taken on an invisible selection.  When an invisible selection is made visible, it should be made visible unselected.

visible/invisible should not be confused with hidden.  hidden is just a category that allows tagged rows to be grouped and toggled invisible together.  So hidden rows can be visible when the hidden filter is disabled and then hidden rows are invisible when the hidden filter is enabled.

At the moment, there are only header filters that can make rows invisible when there is a template loaded because the header with the visibility toggles only appears when a template is loaded, but there should be no reason why the same code that filters out invisible rows can't run even when no template is loaded; it just doesn't have an effect since all rows are visible.

--------------------------------------------editor-state.json overview----------------------------------------------

The purpose of the editor-state.json file is to track any changes that the user is making in the json editor in realtime so that if the page is reloaded, the changes can be re-displayed and the user can still elect to dispose of them without "pushing" them to the template_wip.json file.

The "editor-state.json" file is created as a copy of the template_wip.json file when the json editor is opened and disposed of when the creation editor is closed.  Its status is tracked with the isJsonEditorDirty variable that is initially false on creation of the file, toggles to true if the user makes any changes in the editor-state.json file and toggled to false again if the user clicks the "push changes" button.

When the close button on the json editor is clicked, if isJsonEditorDirty is true, then the save changes dialogue is displayed offering the user the option to push and close, dispose and close or cancel.


-----------------------------------------------------------------

There are two types of images for the purposes of our ecommerce store processes.

The first type are source images.  These are the images that are printed onto products whether they be acrylic panes, t-shirts or coffee mugs.
These images are high resolution (3600x3600 often in my case) rgb webp image files.
These are the images that need to be referenced and included with products that are sent to printify for publishing so that printify has images of high enough resolution to print with appropriate fidelity on products.

I think it makes sense to store these images in the uploads/sip-printify-manager/images directory.  I would like to confirm that that directory can be shared in a way that would allow the images to be available using a browser and also that it is not difficult to assign enough storage capacity on the server to  contain large numbers of large image files.

When these source images are uploaded to printify using the api when a product is created that uses them, the image file is stored on the printify server indefinitely.  That said, I think it makes sense to continue to maintain the source images locally in case there's an issue with printify or in case they need to be available to another PoD.

The second type of images are product images.  These are created by printify when a new product is created.  They show the source image printed on the specified product.  There is a different image for each color variant.  Often there are multiple images showing the product from multiple angles.  These images are sent to wordpress by printify when the product is published and are stored in the wordpress media directories.  In time I'd like to set up an interface in the plugin that allows for these images to be retrieved by the plugin, displayed, edited and deleted, but that will be for later.
----------------------------------------------------------------

SYNC PRODUCTS PROGRESS DIALOGUE - This is a window that tracks and presents the progress of the sync functionality.  It should include the current task in progress, a progress meter designed to update dynamically as the function progresses and a set of summary data that accumulates as the function proceeds.  In the final summary state, it will offer the user the option to make updates to the template_wip file based on the output of the sync function.


Current Task (transient message - shows what is currently the focus)

|---------------------------------------------------------------| (Progress Meter - updates as each step is undertaken)

Summary Data (Persistent summary of steps in the process)
Printify Products Retreived: (number of products fetched).
Blueprint Matches: (number of blueprint matches with the loaded template among the loaded products).
Child Product Id Matches: (number of product matches that share a product id with the loaded template_wip files child products).
Missing Child Products: (number of child products in the template_wip that do not have matches in the printify products).
Status Updates: (number of printify products with statuses that don't match the template_wip child product statuses.
Found Child Products: (number of printify products that satisfy the criteria for being a child product of the loaded template_wip).
Non-Child Products (number of printify products that do NOT satisfy the criteria for being a child product of the loaded template_wip).

Final Summary UI
checkbox : update (n status updates) child product statuses
checkbox : save (n found child products) found child products to template
Update | Cancel (buttons)


--------------------

step one - refresh local products:
Dialogue - Current Task: Fetching Products from Printify using the API
Dialogue - Summary Data: Printify Products Retrieved

Use the get products api call to get products from the printify shop.  Follow the same procedure as is followed when a new shop is loaded.  All existing product json files in the products folder should be deleted.  Each newly fetched product should be saved out as its own json file.  This ensures the local products match the printify products.


step two - find products that may be child-products of the loaded template
Dialogue - Current Task: Finding Child Products for the loaded template
Dialogue - Summary Data: Bueprint Matches

Find all products that have the same blueprint id as the loaded template_wip.

step three - find child products that are already represented in the template_wip file
Dialogue - Current Task: Finding existing matches
Dialogue - Summary Data: Child Product Id Matches
Dialogue - Summary Data: Missing Child Products

Go through each product and check the product id against product ids of child products in the target template.  

step three - update child product status
Dialogue - Current Task: Checking Child Product Status
Dialogue - Summary Data: Status Updates

For each printify product with a matching product id in the template_wip, confirm that the status of the child product in the target template's status is correct.  If the printify product's status is 'unpublished', the template child product's status should be 'created'.  If 'published' then 'published'.

step four: run the product.json being considered through the code that makes it into a template, diff that against the template_wip and evaluate the results to see if the printify product qualifies as a child product of the loaded template.
Dialogue - Current Task: Finding Lost Child Products
Dialogue - Summary Data: Found Child Products
Dialogue - Summary Data: Non-Child Products

Each template.json created from the printify products being considered should be compared with the loaded template_wip json EXCLUDING THE COPIES ARRAY.

The difference between the two files should be extracted. i.e. remove all the matching data from the template.json that was generated from the product being considered.  The remaining data, the difference between the two files, should be evaluated to assess whether it the product being considered meets the criteria for being a child product.  For the purposes of initial development and logging, the difference data should be logged to a file appended with _syncDiffLog and saved in the templates/wip/ folder.

Criteria that qualifies a printify product as a child product of the loaded template is as follows:

If what's left after the diff is some combination of:
    title
    tags
    description
    placeholder.images

then the product being considered is a child product of the target template.


step five: user input based on sync summary data.

checkbox : update n child product statuses
checkbox : save n found child products to template
Update | Cancel (buttons)

Checkboxes should be checked by default.  If the user clicks update with the options selected:
-statuses will be updated to "created", "published" based on the printify product status
-found child products will be added to the template_wip json file in the correct "copies" format
	It's child product id can be generated incrementally based on the existing child products.  
	It's status can be derived from the product status.  unpublished = created, published = published.  
 	the page will be updated so that the interface reflects the updated child product counts.


The correct copies format generally matches the printify product json format for the fields that are present.  The exception is that "location" in the array of any image that may be in the diffed data will need to be established by adding null keys in the locations where there was matching image data in the same array.  Establishing the location of the diffed image will likely need to be handled earlier in the process to ensure it's preserved accurately with correctly placed null keys where matching images in the array may have been.  For example:

        {
            "child_product_id": "fsgp-abstract-01-tee-template_child_product_0064",
            "child_product_title": "FSGP Letter C 08 Tee",
        "tags": []
        "description":
            "status": "Work In Progress",
            "print_areas": [
                {
                    "placeholders": [
                        {
                            "position": "front",
                            "images": [
                                null,
                                null,
                                {
                                    "id": "672ebed27ac912d5bc123f18",
                                    "name": "fsgp_letter_C_08_3600.jpg",
                                    "src": "https:\/\/pfy-prod-image-storage.s3.us-east-2.amazonaws.com\/14758458\/61c1698d-eb80-4c90-837a-01d02b7a3cc3"
                                },
                                null
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}



------------------------------------

RELOAD PRODUCT SEQUENCE...

product-actions.js

	button OR form pass handling to > fetchProductsInChunks

	fetchProductsInChunks 
		js\fetch_products_chunk call → 
		php\sip_fetch_products_chunk → 
			printify api call  → 
			save products to json and database →
			sends success with data →
		js\fetch_products_chunk call →
			updateProgressDialog
			[IF MORE PAGES REPEAT ABOVE]
			[IF DONE reload_shop_products call →
		php\sip_handle_product_action()
			load_products_for_datatables() →
			sends success with data →
		js\handleSuccessResponse
			productTable.destroy();
                    	initializeDataTable();

------------------------------------
SIP PRINTIFY MANAGER ACTION FLOW

User Action → 
JS Form Submit Handler → 						(action_type: product_action: clear_products_database)
JS prepares form data (SiP.Core.utilities.createFormData) →			(action_type: product_action: clear_products_database)				
ajax.js handler (SiP.Core.ajax.handleAjaxAction) →				(action_type: product_action: clear_products_database)

PHP Ajax Handler (sip_handle_ajax_request) →				(case: clear_products_database)
PHP Action Handler (sip_handle_product_action) → 			(sip_clear_products_database)
PHP action-specific function (e.g., sip_remove_product_from_manager) →	(sip_clear_products_database)
PHP Action Handler prepares response →					(action_type: product_action: clear_products_database)  
WordPress sends Ajax response (wp_send_json_success) →			(action_type: product_action: clear_products_database)
ajax.js success handler →						(case: clear_products_database)

Product-specific JS handleSuccessResponse() → 
Product Table Update (destroy and reinitialize)

-----------------------------

PROGRESS METER FILL SOLUTION

If the user has not specified weights for steps, and theaction being tracked has one functional step, consider it to sum 100% of the progress meter.  When it first begins, advance the mater to 20%.  When it completes, advance the meter to 100%.

If the user has not specified weights for steps, and there are multiple actions being tracked, divide the progress meter by the number of actions.  As each action initiates, advance the meter 20% of the portion of the meter allocated to that action.  When it completes, advance the meter to 100% of the portion of the meter allocated to that action.

If the settings specify % for each step in the process... so something like:

upload: 70%
update record: 10%
make title: 5%
create product: 15%

Divide the meter into proportionate segments.  Advance the meter 20% of the proportionate segment on start and to 100% of the proportionate segment on completion.

If there are batches that each contain the proportionate segments, count the batches. For this example let's say 5 batches.
calculate the % of each step.

	upload: 70%/5
	update record: 10%/5
	make title: 5%/5
	create product: 15%/5

So each functional step for each batch, when complete, would advance the progress meter:
	upload: +14%
	update record: +2%
	make title: +1%
	create product: +3%

Display each of these sub-steps in the following increments:
	When each step commences advance the meter 20% of its total to show that it is progressing.
		upload: +2.8%
		update record: +0.4%
		make title: +0.1%
		create product: +0.5%

	If we have interim data that can be used to increment the progression from 20% - 100% apply it proportionately. Otherwise...

	When each step completes advance the meter to 100% of its total
		upload: +14%
		update record: +2%
		make title: +1%
		create product: +3%
	Proceed in this manner until all steps of all batches are complete at which time the meter should be at 100%
