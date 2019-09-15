import { DataProviderUpdateNamespace } from './types';

enum NativeMessageType {
    DataUpdate = 'dataupdate',
    Callback = 'callback',
}

class NativeInterfaceInternalMessage {
    type: NativeMessageType;
    data: any;
    callbackId?: number;
}

export class NativeInterfaceMessage {
    namespace: DataProviderUpdateNamespace;
    functionDefinition: string;
    data: any;
}

export default class NativeInterface {

    private pendingCallbacks: Map<number, (payload: any) => void> = new Map<number, (payload: any) => void>();
    private _pendingCallbackIdentifier: number = 0;

    get _connectionAvailable(): boolean {
        return (window as any).webkit !== undefined && 
               (window as any).webkit.messageHandlers !== undefined &&
               (window as any).webkit.messageHandlers.libwidgetinfo !== undefined;
    }

    protected onDataProviderUpdate(body: any) {}
    private onInternalNativeMessage(message: NativeInterfaceInternalMessage) {
        const messageType = message.type;
        if (messageType === NativeMessageType.Callback) {
            const callbackId = message.callbackId;
            const data = message.data;

            // If there is a valid callback ID, call on it
            if (callbackId !== -1) {
                this.pendingCallbacks[callbackId](data);

                // Remove the pending callback
                this.pendingCallbacks.delete(callbackId);
            }
        } else if (messageType === NativeMessageType.DataUpdate) {
            // Forward data to public stub
            this.onDataProviderUpdate(message.data);
        }
    }

    public sendNativeMessage(body: NativeInterfaceMessage, callback?: (payload: any) => void) {
        if (this._connectionAvailable) {

            // If a callback is specified, cache it client-side
            let callbackId = -1;
            if (callback) {
                callbackId = this._pendingCallbackIdentifier++;
                this.pendingCallbacks.set(callbackId, callback);
            }

            const message = { payload: body, callbackId: callbackId };

            (window as any).webkit.messageHandlers.libwidgetinfo.postMessage(message);
        } else {
            console.error('Cannot send native message, no connection available');
        }
    }

}