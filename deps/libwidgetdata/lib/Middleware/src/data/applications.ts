import { XENDBaseProvider, NativeError, DataProviderUpdateNamespace } from '../types';

export class XENDApplicationsProperties {
    allApplications: XENDApplication[];
}

export class XENDApplication {
    displayName: string;
    bundleIdentifier: string;
    applicationIcon: string;
    badgeValue: string;
    showsInstallationProgress: boolean;
    newlyInstalled: boolean;
    isSystemApplication: boolean;
}

export default class XENDApplicationsProvider extends XENDBaseProvider {

    public get data(): XENDApplicationsProperties {
        return this._data;
    }

    /**
     * Provides a filtered list of applications to only those that are user-installed
     */
    public get userApplications(): XENDApplication[] {
        return (this.data as XENDApplicationsProperties).allApplications.filter((app: XENDApplication) => {
            return !app.isSystemApplication;
        });
    }

    /**
     * Provides a filtered list of applications to only those that are system applications
     */
    public get systemApplications(): XENDApplication[] {
        return (this.data as XENDApplicationsProperties).allApplications.filter((app: XENDApplication) => {
            return app.isSystemApplication;
        });
    }

    /**
     * Launches an application, requesting a device unlock if necessary
     * @param bundleIdentifier The application to launch
     */
    public async launchApplication(bundleIdentifier: string): Promise<NativeError> {
        return new Promise<NativeError>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.Applications,
                functionDefinition: 'launchApplication',
                data: { identifier: bundleIdentifier }
            }, (error: NativeError) => {
                resolve(error);
            });
        });
    }

    /**
     * Deletes an application from the user's device
     * The user will be requested to confirm this action by a dialog.
     * @param identifier The application to delete
     */
    public async deleteApplication(bundleIdentifier: string): Promise<NativeError> {
        return new Promise<NativeError>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.Applications,
                functionDefinition: 'deleteApplication',
                data: { identifier: bundleIdentifier }
            }, (error: NativeError) => {
                resolve(error);
            });
        });
    }
}