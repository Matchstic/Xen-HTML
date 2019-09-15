import { XenHTMLMiddleware, DataProviderUpdateNamespace } from '../types';
import NativeInterface from '../native-interface';

export default class IS2Middleware implements XenHTMLMiddleware {
    public initialise(parent: NativeInterface, providers: Map<DataProviderUpdateNamespace, any>): void {
        // Register observers to the data providers
    }

    public objc_msgSend(object: any, selector: string): void {
        // stringify the incoming object, and figure out what to call
        // Note: native-side parser needs to string-replace 'objc_msgSend' with '_xenhtml_middleware.infostats2.objc_msgSend'
    }
}