import { XenHTMLMiddleware, DataProviderUpdateNamespace } from '../types';
import NativeInterface from '../native-interface';

export default class XenInfoMiddleware implements XenHTMLMiddleware {
    public initialise(parent: NativeInterface, providers: Map<DataProviderUpdateNamespace, any>): void {

    }

    invokeAction(action: any): void {
        
    }
}