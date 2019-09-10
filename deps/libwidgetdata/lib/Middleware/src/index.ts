import IS2Middleware from './infostats2';
import GroovyAPIMiddlware from './groovyapi';
import XenInfoMiddleware from './xeninfo';

import NativeInterface from './native-interface';
import { DataProviderUpdateNamespace, DataProviderUpdate } from './types';

class XENDMiddleware extends NativeInterface {
    private infostats2: IS2Middleware = new IS2Middleware();
    private groovyAPI: GroovyAPIMiddlware = new GroovyAPIMiddlware();
    private xeninfo: XenInfoMiddleware = new XenInfoMiddleware();

    private dataProviders: Map<DataProviderUpdateNamespace, any> = new Map<DataProviderUpdateNamespace, any>();

    public init(): void {
        this.infostats2.initialise(this);
        this.groovyAPI.initialise(this);
        this.xeninfo.initialise(this);

        // Populate data providers
    }

    protected onDataProviderUpdate(update: DataProviderUpdate) {
        // Forward new data to correct provider

        
    }
}

// Setup middleware for native layer to call onto
export const _xenhtml_middleware = new XENDMiddleware();
_xenhtml_middleware.init();

