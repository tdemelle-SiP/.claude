# Mockup Map File Structure Analysis

## Overview
The generated-mockups-map.json contains all mockup data needed to display blueprint mockups. The file has two main sections that work together.

## File Structure

### 1. Map Section (Top)
The "map" object contains groupings of mockup IDs:

```json
{
  "map": {
    "521": [...],    // Color variant group (contains all mockup types for color 521/12100)
    "418": [...],    // Color variant group (contains all mockup types for color 418/12124)
    "Front": [...],  // Mockup type group (contains all color variants of "Front" mockup)
    "Back": [...],   // Mockup type group (contains all color variants of "Back" mockup)
    // etc...
  }
}
```

### 2. Mockup Details Section (Bottom)
Individual mockup objects with full metadata:

```json
{
  "68457f5919c5e1bf2104ad2d_12100_92570_front": {
    "id": "68457f5919c5e1bf2104ad2d_12100_92570_front",
    "type": "GENERATED",
    "src": "https://images.printify.com/mockup/68457f5919c5e1bf2104ad2d/12100/92570/fsgp-moon-02-tee.jpg?camera_label=front",
    "label": "Front",
    "group_key": "521",
    "custom_background": true
  }
}
```

## Mockup ID Pattern
`{productId}_{colorId}_{mockupTypeId}_{mockupName}`

- **productId**: The Printify product ID (e.g., 68457f5919c5e1bf2104ad2d)
- **colorId**: The color variant ID (e.g., 12100, 12124, 12052)
- **mockupTypeId**: The mockup type identifier (e.g., 92570, 92571)
- **mockupName**: Human-readable mockup name (e.g., front, back, folded)

## Color Variants
Each color has a numeric ID and group_key:
- 12100 → group_key "521" (appears to be first/default color)
- 12124 → group_key "418"
- 12052 → group_key "463"
- etc.

## Mockup Types Available
Based on the sample, these mockup types are available:
- Front / Back / Front 2 / Back 2
- Folded
- Hanging 1 / Hanging 2 / Hanging 3
- Front Collar Closeup / Back Collar Closeup
- Person 1-10 (various poses, front/back views)
- Person sleeve closeups
- Lifestyle / Duo / Duo 2 / Duo 3
- Size Chart

## Implementation Strategy

### For Blueprint Mockups (Product-Agnostic)
Since blueprints are not product-specific, we should:

1. **Use ONE color variant only** - Pick the first color (e.g., 12100/group_key "521")
2. **Extract unique mockup types** - Get one of each type (Front, Back, Folded, etc.)
3. **Focus on product-only mockups** - Prioritize mockups without models/lifestyle shots

### Recommended Mockup Selection
For blueprint rows, show these core mockups:
- Front
- Back
- Front 2 / Back 2 (alternate angles)
- Folded
- Hanging views (1-3)
- Collar closeups

### Data Extraction Process
1. Parse the map file
2. Get all mockup IDs for the first color variant (e.g., group "521")
3. For each ID in that group, get the full mockup data
4. Extract the image URL from the "src" field
5. Save mockup metadata with simplified structure

### Simplified Metadata Structure
```json
{
  "blueprint_id": "6",
  "product_id": "68457f5919c5e1bf2104ad2d",
  "generated_at": "2025-01-14T12:00:00Z",
  "mockup_types": [
    {
      "id": "front",
      "label": "Front",
      "mockup_type_id": "92570",
      "image_url": "https://images.printify.com/mockup/.../92570/..."
    }
  ]
}
```

## Base Mockup Discovery
The mockup URLs follow this pattern:
`https://images.printify.com/mockup/{productId}/{colorId}/{mockupTypeId}/{productSlug}.jpg?camera_label={label}`

There might be base mockups without product designs at:
`https://images.printify.com/mockup/blank/{mockupTypeId}/base.jpg`

This needs further investigation through the extension.