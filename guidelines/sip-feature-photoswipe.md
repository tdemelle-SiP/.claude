# PhotoSwipe Integration

This feature integrates with [DataTables](./sip-feature-datatables.md#thumbnail-integration) for image galleries.

Image lightbox implementation in SiP plugins using PhotoSwipe v5.3.0.

## Setup

### Loading PhotoSwipe Assets

```php
// In enqueue_admin_scripts()
wp_enqueue_style('photoswipe-css', 
    plugin_dir_url(__FILE__) . 'assets/photoswipe/photoswipe.css', 
    [], 
    '5.3.0'
);
wp_enqueue_script('photoswipe', 
    plugin_dir_url(__FILE__) . 'assets/photoswipe/photoswipe.umd.min.js', 
    [], 
    '5.3.0', 
    true
);
wp_enqueue_script('photoswipe-lightbox', 
    plugin_dir_url(__FILE__) . 'assets/photoswipe/photoswipe-lightbox.umd.min.js', 
    ['photoswipe'], 
    '5.3.0', 
    true
);

// Add type="module" attribute
public function add_type_attribute($tag, $handle, $src) {
    $module_scripts = ['photoswipe', 'photoswipe-lightbox'];
    if (in_array($handle, $module_scripts)) {
        $tag = str_replace('<script ', '<script type="module" ', $tag);
    }
    return $tag;
}
```

## Implementation

### Initialize PhotoSwipe

```javascript
function initPhotoSwipe() {
    if (typeof PhotoSwipeLightbox === 'undefined') {
        console.error('PhotoSwipeLightbox is not defined');
        return;
    }

    // Create lightbox for multiple containers
    const lightbox = new PhotoSwipeLightbox({
        gallery: '#shop-container, #product-table-container, #template-table-container, #image-table-container, #creation-table-container',
        children: 'a.pswp-item',
        pswpModule: PhotoSwipe,
        preloaderDelay: 0
    });
    
    // Initialize
    lightbox.init();
    
    // Store instance
    SiP.PrintifyManager.utilities.photoswipeLightbox = lightbox;
}
```

### Create Thumbnail Function

```javascript
function createThumbnail(imageData, options = {}) {
    const defaults = {
        thumbnailSize: 24,
        cssClass: 'sip-thumb',
        usePhotoSwipe: true,
        lazyLoad: false,
        containerClass: ''
    };

    const settings = {...defaults, ...options};

    if (!imageData || (!imageData.src && !imageData.input_text)) {
        return '';
    }

    let html = '';

    // Container wrapper if needed
    if (settings.containerClass) {
        html += `<div class="${settings.containerClass}">`;
    }

    // PhotoSwipe link wrapper
    if (imageData.src && settings.usePhotoSwipe) {
        const defaultDimension = 800;
        html += `<a href="${imageData.src}" 
            data-pswp-src="${imageData.src}" 
            data-pswp-width="${imageData.width || defaultDimension}" 
            data-pswp-height="${imageData.height || defaultDimension}" 
            class="pswp-item">`;
    }

    // Thumbnail image
    html += `<img src="${imageData.src}" 
        alt="${imageData.name || ''}" 
        class="${settings.cssClass}" 
        style="width:${settings.thumbnailSize}px; height:auto;"
        ${settings.lazyLoad ? 'loading="lazy"' : ''}>`;
    
    if (settings.usePhotoSwipe) {
        html += `</a>`;
    }

    if (settings.containerClass) {
        html += `</div>`;
    }

    return html;
}
```

## Event Handlers

### Custom Caption

```javascript
lightbox.on('uiRegister', function() {
    lightbox.pswp.ui.registerElement({
        name: 'custom-caption',
        order: 9,
        isButton: false,
        appendTo: 'root',
        html: '',
        onInit: (el, pswp) => {
            lightbox.pswp.on('change', () => {
                const currSlideElement = lightbox.pswp.currSlide.data.element;
                let captionText = '';
                
                if (currSlideElement) {
                    captionText = currSlideElement.getAttribute('data-caption') || 
                                 currSlideElement.getAttribute('title') || 
                                 currSlideElement.querySelector('img')?.getAttribute('alt') || '';
                }
                
                el.innerHTML = captionText;
            });
        }
    });
});
```

### Missing Dimensions Handler

```javascript
lightbox.on('contentLoad', function(e) {
    const { content, isLazy } = e;
    
    if (content.type === 'image' && (!content.width || !content.height)) {
        e.preventDefault();
        
        // Try element attributes first
        const element = content.element;
        const width = element?.getAttribute('data-pswp-width');
        const height = element?.getAttribute('data-pswp-height');
        
        if (width && height && parseInt(width) > 0) {
            content.width = parseInt(width);
            content.height = parseInt(height);
            content.onLoaded();
        } else {
            // Load image to get natural dimensions
            const img = new Image();
            
            img.onload = function() {
                content.width = img.naturalWidth;
                content.height = img.naturalHeight;
                
                // Store dimensions for future use
                if (element) {
                    element.setAttribute('data-pswp-width', img.naturalWidth);
                    element.setAttribute('data-pswp-height', img.naturalHeight);
                }
                
                content.onLoaded();
            };
            
            img.onerror = function() {
                // Fallback dimensions
                content.width = 800;
                content.height = 800;
                content.onLoaded();
            };
            
            img.src = content.src;
        }
    }
});
```

## Update Dimensions

```javascript
function updatePhotoSwipeDimensions() {
    const containerSelectors = [
        '#shop-container', 
        '#product-table-container', 
        '#template-table-container', 
        '#image-table-container', 
        '#creation-table-container'
    ];
    
    containerSelectors.forEach(selector => {
        const container = $(selector);
        if (container.length) {
            container.find('a.pswp-item').each(function() {
                const link = $(this);
                const img = link.find('img')[0];
                
                if (img && img.naturalWidth) {
                    link.attr('data-pswp-width', img.naturalWidth);
                    link.attr('data-pswp-height', img.naturalHeight);
                }
            });
        }
    });
}
```

## Usage in DataTables

```javascript
columns: [
    {
        data: "image",
        render: function(data, type, row) {
            // Use createThumbnail for PhotoSwipe integration
            const thumbnail = SiP.PrintifyManager.utilities.createThumbnail(row, {
                thumbnailSize: 50,
                containerClass: 'image-cell',
                usePhotoSwipe: true
            });
            
            return thumbnail;
        }
    }
]
```

## Required HTML Structure

### Basic Gallery Item
```html
<a href="full-image.jpg" 
   data-pswp-src="full-image.jpg" 
   data-pswp-width="1200" 
   data-pswp-height="800" 
   class="pswp-item">
    <img src="thumbnail.jpg" alt="Image description">
</a>
```

### Container Structure
```html
<div id="product-table-container">
    <!-- Gallery items here -->
</div>
```

## Configuration Options

```javascript
const lightbox = new PhotoSwipeLightbox({
    gallery: '.gallery-selector',    // Container selector
    children: 'a.pswp-item',        // Item selector
    pswpModule: PhotoSwipe,         // Module reference
    preloaderDelay: 0,              // Disable preloader
    loop: true,                     // Enable looping
    escKey: true,                   // Close on ESC
    arrowKeys: true,                // Navigate with arrows
    bgOpacity: 0.85,                // Background opacity
    spacing: 0.12,                  // Spacing between slides
    maxZoomLevel: 4,                // Maximum zoom
    pinchToClose: true             // Pinch gesture to close
});
```

## CSS Customization

```css
/* Thumbnail styling */
.sip-thumb {
    cursor: pointer;
    transition: transform 0.2s;
}

.sip-thumb:hover {
    transform: scale(1.1);
}

/* Gallery link styling */
a.pswp-item {
    display: inline-block;
    text-decoration: none;
}

/* Container styling */
.image-cell {
    text-align: center;
}
```

## Best Practices

1. **Always include dimensions**
```javascript
data-pswp-width="1200" 
data-pswp-height="800"
```

2. **Handle missing dimensions**
```javascript
// Fallback to 800x800 if dimensions unknown
const defaultDimension = 800;
```

3. **Update dimensions after dynamic content**
```javascript
// After AJAX load
updatePhotoSwipeDimensions();
```

4. **Use consistent selectors**
```javascript
gallery: '#container-id',
children: 'a.pswp-item'
```

## Checklist

- [ ] Load PhotoSwipe CSS and JS files
- [ ] Add type="module" attribute to scripts
- [ ] Initialize PhotoSwipe on page load
- [ ] Use `createThumbnail()` for consistent markup
- [ ] Include dimensions in data attributes
- [ ] Handle missing dimensions with fallback
- [ ] Update dimensions for dynamic content
- [ ] Use consistent CSS classes (`pswp-item`)
- [ ] Test with various image sizes