const fs = require('fs');
const path = require('path');
const AdmZip = require('adm-zip');

// Read the working v1.0.2.11 pbiviz file
const oldPbivizPath = 'dist/rPivotTable8B3D024D64314B469FFC4852A7ACBD5F.1.0.2.11.pbiviz';
const zip = new AdmZip(oldPbivizPath);
const pbivizJsonEntry = zip.getEntry('resources/rPivotTable8B3D024D64314B469FFC4852A7ACBD5F.pbiviz.json');
const pbivizJson = JSON.parse(pbivizJsonEntry.getData().toString('utf8'));

// Read the new compiled visual.js
const newJsCode = fs.readFileSync('.tmp/build/visual.js', 'utf8');

// Read the new R script
const newRScript = fs.readFileSync('script.r', 'utf8');

// Update the pbiviz.json
pbivizJson.visual.version = '1.0.2.12';
pbivizJson.visual.description = 'R Pivot Table from BlueGranite - Greek characters fixed (JavaScript unescape)';

// Update the JavaScript code
pbivizJson.content.js = newJsCode;

// Update the R script
pbivizJson.capabilities.dataViewMappings[0].scriptResult.script.scriptSourceDefault = newRScript;

// Write the updated pbiviz.json
const outputDir = '.tmp/package-manual/resources';
fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(
    path.join(outputDir, 'rPivotTable8B3D024D64314B469FFC4852A7ACBD5F.pbiviz.json'),
    JSON.stringify(pbivizJson)
);

console.log('Updated pbiviz.json created successfully');
console.log(`New JS code size: ${newJsCode.length} bytes`);
console.log(`New R script size: ${newRScript.length} bytes`);
