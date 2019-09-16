import IS2Middleware from './infostats2';
import GroovyAPIMiddlware from './groovyapi';
import XenInfoMiddleware from './xeninfo';

import { DataProviderUpdateNamespace, DataProviderUpdate } from './types';
import XENDCalendarProvider from './data/calendar';
import XENDMediaProvider from './data/media';
import XENDRemindersProvider from './data/reminders';
import XENDSystemProvider from './data/system';
import XENDWeatherProvider from './data/weather';
import XENDApplicationsProvider from './data/applications';
import XENDResourceStatisticsProvider from './data/resource-statistics';

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
        this.dataProviders.set(DataProviderUpdateNamespace.Calendar, new XENDCalendarProvider(this));
        this.dataProviders.set(DataProviderUpdateNamespace.Media, new XENDMediaProvider(this));
        this.dataProviders.set(DataProviderUpdateNamespace.Reminders, new XENDRemindersProvider(this));
        this.dataProviders.set(DataProviderUpdateNamespace.System, new XENDSystemProvider(this));
        this.dataProviders.set(DataProviderUpdateNamespace.Weather, new XENDWeatherProvider(this));
        this.dataProviders.set(DataProviderUpdateNamespace.Applications, new XENDApplicationsProvider(this));
        this.dataProviders.set(DataProviderUpdateNamespace.Resources, new XENDResourceStatisticsProvider(this));

        // Setup backwards compatibility middlewares
        this.infostats2.initialise(this, this.dataProviders);
        this.groovyAPI.initialise(this, this.dataProviders);
        this.xeninfo.initialise(this, this.dataProviders);
    }

    protected onDataProviderUpdate(update: DataProviderUpdate) {
        // Forward new data to correct provider
        this.dataProviders.get(update.namespace)._setData(update.payload);
    }

    public dataProviderInNamespace(namespace: DataProviderUpdateNamespace) {
        return this.dataProviders.get(namespace);
    }
}

// This is made available to widgets as a global 'var WidgetInfo = { ... }'
// The magic of webpack eh
export default class WidgetInfo {
    // Called onto by native via 'WidgetInfo._middleware'
    private _middleware = new XENDMiddleware();

    // Aliases to providers
    public calendar: XENDCalendarProvider             = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.Calendar);
    public media: XENDMediaProvider                   = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.Media);
    public reminders: XENDRemindersProvider           = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.Reminders);
    public system: XENDSystemProvider                 = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.System);
    public weather: XENDWeatherProvider               = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.Weather);
    public apps: XENDApplicationsProvider             = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.Applications);
    public resources: XENDResourceStatisticsProvider = this._middleware.dataProviderInNamespace(DataProviderUpdateNamespace.Resources);
}