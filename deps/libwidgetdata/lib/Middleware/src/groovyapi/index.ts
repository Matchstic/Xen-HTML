
// See: https://web.archive.org/web/20150910231544/http://groovycarrot.co.uk/groovyapi/
import { XenHTMLMiddleware } from '../types';
import NativeInterface from '../native-interface';

export default class GroovyAPIMiddleware implements XenHTMLMiddleware {
    public initialise(parent: NativeInterface): void {
        // @ts-ignore
        window.groovyAPI = this;
    }

    do(action: any, callback: () => void): void {
        
    }
}
