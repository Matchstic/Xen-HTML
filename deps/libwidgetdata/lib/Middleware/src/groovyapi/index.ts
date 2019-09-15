
// See: https://web.archive.org/web/20150910231544/http://groovycarrot.co.uk/groovyapi/
import { XenHTMLMiddleware, DataProviderUpdateNamespace } from '../types';
import NativeInterface from '../native-interface';

export default class GroovyAPIMiddleware implements XenHTMLMiddleware {
    public initialise(parent: NativeInterface, providers: Map<DataProviderUpdateNamespace, any>): void {
        (window as any).groovyAPI = this;
    }

    do(action: any, callback: () => void): void {
        
    }
}
