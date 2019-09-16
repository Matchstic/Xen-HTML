import NativeInterface from './native-interface';

export interface XenHTMLMiddleware {
    initialise(parent: NativeInterface, providers: Map<DataProviderUpdateNamespace, any>): void;
}

export enum DataProviderUpdateNamespace {
    Weather = 'weather',
    Media = 'media',
    Calendar = 'calendar',
    Reminders = 'reminders',
    Resources = 'resources',
    Applications = 'applications',
    System = 'system'
}

export class DataProviderUpdate {
    namespace: DataProviderUpdateNamespace;
    payload: any;
}

export class NativeError {
    code: number;
    message: string;
}

export class XENDBaseProvider {

    constructor(protected connection: NativeInterface) {

    }

    private observers: Array<(newData: any) => void> = [];

    protected _data: any = {};
    get data() {
        return this._data;
    }

    _setData(payload: any) {
        this._data = payload;

        // Notify observers of change
        this.observers.forEach((fn: (newdata: any) => void) => {
            fn(this.data);
        });
    }

    /**
     * Add a function that gets called whenever the data of this
     * provider changes.
     * 
     * The new data is provided as the parameter into your callback function.
     * 
     * @param callback A callback that is notified whenever the provider's data change
     */
    public observeData(callback: (newData: any) => void) {
        this.observers.push(callback);
    }
}