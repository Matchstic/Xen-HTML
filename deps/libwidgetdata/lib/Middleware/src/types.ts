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