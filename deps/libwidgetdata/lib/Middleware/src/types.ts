import NativeInterface from './native-interface';

export interface XenHTMLMiddleware {
    initialise(parent: NativeInterface): void;
}

export enum DataProviderUpdateNamespace {
    Weather = 'weather',
    Media = 'media',
    Calendar = 'calendar',
    Reminders = 'reminders',
    System = 'system'
}

export class DataProviderUpdate {
    namespace: DataProviderUpdateNamespace;
    payload: any;
}

export class XENDBaseProvider {
    private observers: Array<(newProperties: any) => void> = [];

    private _properties: any = {};
    get properties() {
        return this._properties;
    }

    set properties(payload: any) {
        this._properties = payload;

        // Notify observers of change
        this.observers.forEach((fn: (newProperties: any) => void) => {
            fn(this.properties);
        });
    }

    /**
     * Add a function that gets called whenever the properties of this data
     * provider changes.
     * 
     * The new properties are provided as the parameter into your callback function.
     * 
     * @param callback A callback that is notified whenever the provider's properties change
     */
    public observeProperties(callback: (newProperties: any) => void) {
        this.observers.push(callback);
    }
}