import { Visual } from "../../.api/v1.10.0/PowerBI-visuals.d";
import powerbiVisualsApi from "powerbi-visuals-api";
import IVisualPlugin = powerbiVisualsApi.visuals.plugins.IVisualPlugin;
import VisualConstructorOptions = powerbiVisualsApi.extensibility.visual.VisualConstructorOptions;

var powerbiKey: any = "powerbi";
var powerbi: any = window[powerbiKey];
var rPivotTable8B3D024D64314B469FFC4852A7ACBD5F: IVisualPlugin = {
    name: 'rPivotTable8B3D024D64314B469FFC4852A7ACBD5F',
    displayName: 'R Pivot Table',
    class: 'Visual',
    apiVersion: '1.13.0',
    create: (options?: VisualConstructorOptions) => {
        if (Visual) {
            return new Visual(options);
        }
        throw 'Visual instance not found';
    },
    
    custom: true
};
if (typeof powerbi !== "undefined") {
    powerbi.visuals = powerbi.visuals || {};
    powerbi.visuals.plugins = powerbi.visuals.plugins || {};
    powerbi.visuals.plugins["rPivotTable8B3D024D64314B469FFC4852A7ACBD5F"] = rPivotTable8B3D024D64314B469FFC4852A7ACBD5F;
}
export default rPivotTable8B3D024D64314B469FFC4852A7ACBD5F;