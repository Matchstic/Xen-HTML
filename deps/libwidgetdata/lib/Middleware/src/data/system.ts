import { XENDBaseProvider, DataProviderUpdateNamespace } from '../types';
import { NativeInterfaceMessage } from '../native-interface';

export class XENDSystemProperties {
    deviceName: string;
    deviceType: string;
    deviceModel: string;
    deviceModelPromotional: string;
    systemVersion: string;

    deviceDisplayHeight: number;
    deviceDisplayWidth: number;
    deviceDisplayBrightness: number;

    isTwentyFourHourTimeEnabled: boolean;
    isLowPowerModeEnabled: boolean;
    isNetworkConnected: boolean;
}

export default class XENDSystemProvider extends XENDBaseProvider {

    public get data(): XENDSystemProperties {
        return this._data;
    }

    /**
     * TODO docs
     */
    public async invokeScreenshot(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'invokeScreenshot',
                data: {}
            }, () => {
                resolve();
            });
        });
    }

    /**
     * TODO docs
     */
    public async lockDevice(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'lockDevice',
                data: {}
            }, () => {
                resolve();
            });
        });
    }

    /**
     * TODO docs
     */
    public async openApplicationSwitcher(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'openApplicationSwitcher',
                data: {}
            }, () => {
                resolve();
            });
        });
    }

    /**
     * TODO docs
     */
    public async openSiri(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'openSiri',
                data: {}
            }, () => {
                resolve();
            });
        });
    }

    /**
     * TODO docs
     */
    public async respringDevice(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'respringDevice',
                data: {}
            }, () => {
                resolve();
            });
        });
    }

    /**
     * TODO docs
     */
    public async vibrateDevice(duration: number = 0.25): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'vibrateDevice',
                data: { duration: duration }
            }, () => {
                resolve();
            });
        });
    }

    /**
     * TODO docs
     */
    public async log(message: string): Promise<void> {
        return new Promise<void>((resolve, reject) => {

            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.System,
                functionDefinition: 'log',
                data: { message: message }
            }, () => {
                resolve();
            });

        });
    }
}