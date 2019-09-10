enum NativeMessageType {
    DataUpdate = 'dataupdate',
    Callback = 'callback',
}

export default class NativeInterface {

    private _connectionAvailable: boolean;
    private pendingCallbacks: Map<number, (payload: any) => void> = new Map<number, (payload: any) => void>();
    private _pendingCallbackIdentifier: number = 0;

    constructor() {
        this._connectionAvailable = (window as any).webkit !== undefined && 
                                    (window as any).webkit.messageHandlers !== undefined &&
                                    (window as any).webkit.messageHandlers.xenhtml !== undefined;
    }

    protected onDataProviderUpdate(body: any) {}
    private onInternalNativeMessage(messageType: string, body: any) {
        if (messageType === NativeMessageType.Callback) {
            const callbackId = body.callbackid;
            const data = body.data;

            // If there is a valid callback ID, call on it
            if (callbackId !== -1) {
                this.pendingCallbacks[callbackId](data);

                // Remove the pending callback
                this.pendingCallbacks.delete(callbackId);
            }
        } else if (messageType === NativeMessageType.DataUpdate) {
            // Forward data to public stub
            this.onDataProviderUpdate(body);
        }
    }

    public sendNativeMessage(body: any, callback?: (payload: any) => void) {
        if (this._connectionAvailable) {

            // If a callback is specified, cache it client-side
            let callbackId = -1;
            if (callback) {
                callbackId = this._pendingCallbackIdentifier++;
                this.pendingCallbacks.set(callbackId, callback);
            }

            const message = { payload: body, callbackid: callbackId };

            (window as any).webkit.messageHandlers.xenhtml.postMessage(message);
        } else {
            console.log('Cannot send native message, no connection available');
        }
    }

}