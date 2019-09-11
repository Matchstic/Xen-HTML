import IS2Middleware from './infostats2';
import GroovyAPIMiddlware from './groovyapi';
import XenInfoMiddleware from './xeninfo';

import { DataProviderUpdateNamespace, DataProviderUpdate } from './types';
import XENDCalendarProvider from './data/calendar';
import XENDMediaProvider from './data/media';
import XENDRemindersProvider from './data/reminders';
import XENDSystemProvider from './data/system';
import XENDWeatherProvider from './data/weather';

import NativeInterface from './native-interface';

class XENDMiddleware extends NativeInterface {
    private infostats2: IS2Middleware = new IS2Middleware();
    private groovyAPI: GroovyAPIMiddlware = new GroovyAPIMiddlware();
    private xeninfo: XenInfoMiddleware = new XenInfoMiddleware();

    private dataProviders: Map<DataProviderUpdateNamespace, any> = new Map<DataProviderUpdateNamespace, any>();

    constructor() {
        super();
        this.init();
    }

    private init(): void {
        // Populate data providers
        this.dataProviders.set(DataProviderUpdateNamespace.Calendar, new XENDCalendarProvider());
        this.dataProviders.set(DataProviderUpdateNamespace.Media, new XENDMediaProvider());
        this.dataProviders.set(DataProviderUpdateNamespace.Reminders, new XENDRemindersProvider());
        this.dataProviders.set(DataProviderUpdateNamespace.System, new XENDSystemProvider());
        this.dataProviders.set(DataProviderUpdateNamespace.Weather, new XENDWeatherProvider());

        // Setup backwards compatibility middlewares
        this.infostats2.initialise(this);
        this.groovyAPI.initialise(this);
        this.xeninfo.initialise(this);
    }

    protected onDataProviderUpdate(update: DataProviderUpdate) {
        // Forward new data to correct provider
        this.dataProviders.get(update.namespace).properties = update.payload;
    }
}

// Setup middleware for native layer to call onto
export const _xenhtml_middleware = new XENDMiddleware();

