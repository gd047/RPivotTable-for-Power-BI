# Greek Characters Fix - Testing Log

## Problem Statement

The RPivotTable Power BI custom visual does not display Greek characters correctly. Greek text appears as garbled characters or HTML entities instead of the actual Greek letters.

**Example:**
- Expected: `ΣΑΕ` (Greek letters)
- Actual: `Î£Î'Î•` (garbled) or `&#931;&#913;&#917;` (HTML entities visible)

## Root Cause Analysis

Based on research and testing:

1. **Known Issue Since 2018**: This is a documented problem affecting multiple languages (Greek, Norwegian, etc.) in Power BI R custom visuals
2. **Server-Side R Engine Encoding**: The Power BI R engine doesn't properly respect UTF-8 encoding when processing data
3. **No Official Microsoft Fix**: Despite being reported since 2018, there's no official solution from Microsoft
4. **Affects Both Desktop & Service**: The issue occurs in both Power BI Desktop and Power BI Service

## Testing History

### Version 1.0.2.9 - HTML Entity Conversion (R-based)
**Date**: Nov 3, 2025
**Approach**: Convert Greek characters to HTML entities in R script after rpivotTable rendering

**Changes**:
```r
# Added UTF-8 encoding setup
Sys.setlocale("LC_ALL", "en_US.UTF-8")
Values <- as.data.frame(lapply(Values, enc2utf8))

# After saveWidget, convert to HTML entities
convertToEntities <- function(text) {
  chars <- strsplit(text, "")[[1]]
  result <- sapply(chars, function(ch) {
    code <- utf8ToInt(ch)
    if(code > 127) paste0("&#", code, ";") else ch
  })
  paste(result, collapse = "")
}
html_content <- sapply(html_content, convertToEntities)
```

**Result**: ⚠️ HTML entities were visible in the output (`&#931;&#913;&#917;` instead of `ΣΑΕ`)
- **Good**: Entities were correctly generated and passed through encoding layers
- **Bad**: Browser didn't auto-decode them

**File**: `RPivotTable-1.0.2.9-Greek-Fixed.pbiviz`

---

### Version 1.0.2.10 - HTML Entity Post-Render
**Date**: Nov 3, 2025
**Approach**: Similar to 1.0.2.9 but with refined HTML entity conversion

**Changes**:
- Same R-based HTML entity conversion
- Attempted to improve the conversion logic

**Result**: ⚠️ Same as 1.0.2.9 - HTML entities visible but not decoded
- Screenshot saved: `RPivotTable-1.0.2.10.png`

**File**: `RPivotTable-1.0.2.10-Greek-PostRender.pbiviz`

---

### Version 1.0.2.11 - Double-Escape Fix Attempt
**Date**: Nov 4, 2025
**Approach**: Added extra step to fix double-escaped entities from saveXML()

**Changes**:
```r
# After initial conversion
html_content <- sapply(html_content, convertToEntities)
writeLines(html_content, 'out.html', useBytes = FALSE)

# Fix double-escaped entities (&#931; becomes &amp;#931; after saveXML)
html_final <- readLines('out.html', encoding = "UTF-8", warn = FALSE)
html_final <- gsub("&amp;#(\\d+);", "&#\\1;", html_final)
writeLines(html_final, 'out.html', useBytes = FALSE)
```

**Result**: ❌ **FAILED** - Blank display (white screen)
- **Cause**: The R script converted the entire HTML file (including tags) to entities, making it invalid HTML

**File**: `RPivotTable-1.0.2.11-Greek-Fixed.pbiviz`

---

### Version 1.0.2.12 - JavaScript Client-Side Unescape (CURRENT)
**Date**: Nov 4, 2025
**Approach**: Remove all R-based HTML manipulation, add JavaScript unescape on client-side

**Changes**:

1. **Removed from R script (`source/script.r`)**:
   - All UTF-8 encoding setup
   - All HTML entity conversion
   - Post-processing of HTML output
   - Script is now clean, only generates pivot table

2. **Added to TypeScript (`source/src/visual.ts`)**:
```typescript
private unescapeHTMLEntities(): void {
    const unescapeTextNodes = (node: Node) => {
        if (node.nodeType === Node.TEXT_NODE) {
            // Only process text nodes that contain HTML entities
            if (node.textContent && /&#\d+;/.test(node.textContent)) {
                const div = document.createElement('div');
                div.innerHTML = node.textContent;
                node.textContent = div.textContent;
            }
        } else if (node.nodeType === Node.ELEMENT_NODE) {
            const childNodes = node.childNodes;
            for (let i = 0; i < childNodes.length; i++) {
                unescapeTextNodes(childNodes[i]);
            }
        }
    };

    this.bodyNodes.forEach(node => unescapeTextNodes(node));
}

// Called after rendering
RunHTMLWidgetRenderer((config) => {
    this.keepSettings(JSON.stringify(config));
    this.unescapeHTMLEntities(); // NEW
});
```

3. **Fixed compilation errors**:
   - Changed `NodeListOf<HTMLHeadElement>` to `HTMLCollectionOf<HTMLHeadElement>`
   - Changed `Array.from()` to traditional for loop (ES5 compatibility)
   - Added eslint-disable comments for necessary innerHTML usage

**Build Details**:
- Compiled TypeScript: `source/.tmp/build/visual.js` (28KB)
- Updated R script: `source/script.r` (5.2KB)
- Final package: `RPivotTable-1.0.2.12-Greek-Fixed.pbiviz` (9.6KB compressed, 38KB uncompressed)

**Theory**:
- If R generates HTML entities, JavaScript will unescape them client-side
- If R generates garbled text, this won't help (no entities to unescape)

**Result**: 🔄 **PENDING USER TESTING**

**Files**:
- `RPivotTable-1.0.2.12-Greek-Fixed.pbiviz`
- `source/update-pbiviz.js` (Node.js script for manual package building)

---

## Technical Details

### File Structure of .pbiviz Package
```
.pbiviz (ZIP archive)
├── package.json (metadata, version info)
└── resources/
    └── rPivotTable8B3D024D64314B469FFC4852A7ACBD5F.pbiviz.json
        ├── visual (metadata)
        ├── capabilities (data mappings, R script)
        │   └── scriptSourceDefault (R script source code)
        ├── content
        │   └── js (compiled JavaScript/TypeScript code)
        └── dependencies
```

### Encoding Flow in Power BI R Visuals

```
Power BI Data (UTF-8)
    ↓
R Engine reads with encoding="UTF-8"
    ↓
R processes data → Creates HTML with htmlwidgets
    ↓ [ENCODING ISSUE HAPPENS HERE]
HTML returned to Power BI (may be garbled)
    ↓
Power BI renders HTML in iframe
    ↓
JavaScript can process DOM (v1.0.2.12)
```

### Why File Size Varies

| Version | pbiviz.json (uncompressed) | .pbiviz (compressed) |
|---------|---------------------------|---------------------|
| 1.0.2.11 | 22 KB | 23 KB |
| 1.0.2.12 | 38 KB | 9.6 KB |

**Explanation**: v1.0.2.12 contains MORE code (compiled TypeScript) but compresses better due to JavaScript's repetitive structure.

## Key Findings

### What Works
✅ R can generate HTML entities successfully (proven in v1.0.2.9-10)
✅ HTML entities survive the encoding pipeline
✅ TypeScript compilation and integration
✅ JavaScript can access and manipulate DOM after rendering

### What Doesn't Work
❌ Browser auto-decoding of HTML entities in R-generated content
❌ R-based post-processing of entire HTML (breaks structure)
❌ Server-side UTF-8 encoding fixes

### What We Don't Know Yet
❓ Does the R engine produce HTML entities or garbled text by default?
❓ Can client-side JavaScript unescape work if entities are present?
❓ Is there ANY way to fix this with the current Power BI R visuals framework?

## Lessons Learned

1. **Don't Modify Entire HTML**: Converting the entire HTML output to entities breaks the structure (v1.0.2.11 failure)

2. **HTML Entities Are the Right Approach**: They bypass all encoding layers and are pure ASCII

3. **Timing Matters**: Processing must happen at the right stage:
   - Too early (before rpivotTable): May work, needs testing
   - On final HTML (v1.0.2.9-11): Entities visible but not decoded
   - Client-side after render (v1.0.2.12): Theory untested

4. **Power BI R Framework Limitations**: This is a known, unfixed issue since 2018 affecting multiple languages

## Next Steps / Alternatives

### If v1.0.2.12 Fails

**Option A: Pre-rpivotTable HTML Entity Conversion**
Convert data values to HTML entities BEFORE calling rpivotTable():
```r
Values <- as.data.frame(lapply(Values, function(col) {
  if(is.character(col) || is.factor(col)) {
    # Convert each character to HTML entity
  }
  col
}))
# THEN call rpivotTable(Values, ...)
```

**Option B: Accept Limitation**
- Document that Greek characters are not supported
- Recommend using Power BI native table visual instead
- Wait for Microsoft to fix the R engine encoding

**Option C: Alternative Approach**
- Switch from R-based visual to TypeScript-based custom visual
- Use a JavaScript pivot table library instead of rpivotTable
- Full control over encoding, no R engine issues

## References

- [Microsoft Community: R Custom Visual International Characters](https://community.powerbi.com/)
- [R Script Encoding Issues in Power BI Service](https://github.com/microsoft/powerbi-visuals-tools)
- Original template: [Microsoft PowerBI-visuals-tools](https://github.com/microsoft/PowerBI-visuals-sampleBarChart)

## Commit History

- `aecb088`: Fix Greek characters: HTML entities after rendering (v1.0.2.10)
- `d486fe4`: Add Greek character support with HTML entities (v1.0.2.9)
- `99d3bfd`: version 1.0.2.11 (failed - blank display)
- `61d38bb`: Fix Greek character display with JavaScript unescape (v1.0.2.12)

## Testing Checklist for v1.0.2.12

When testing `RPivotTable-1.0.2.12-Greek-Fixed.pbiviz`:

- [ ] Import visual to Power BI Desktop
- [ ] Add data with Greek characters
- [ ] Check what appears:
  - [ ] Garbled text (`Î£Î'Î•`) → R not producing entities
  - [ ] HTML entities (`&#931;&#913;&#917;`) → JavaScript unescape failed
  - [ ] Correct Greek (`ΣΑΕ`) → SUCCESS! 🎉
- [ ] Test with different Greek text (capital, lowercase, accents)
- [ ] Test column names with Greek characters
- [ ] Test numeric values with Greek labels
- [ ] Verify pivot table functionality still works

---

*Last Updated: November 4, 2025*
*Current Version Under Test: 1.0.2.12*
*Status: Awaiting test results*
