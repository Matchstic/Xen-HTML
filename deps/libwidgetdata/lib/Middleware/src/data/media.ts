import { XENDBaseProvider, DataProviderUpdateNamespace } from '../types';
import { XENDApplication } from './applications';

export class XENDMediaAlbum {
    title: string;
    tracks: XENDMediaTrack[];
    trackCount: number;
}

export class XENDMediaArtist {
    name: string;
    albums: XENDMediaAlbum;
}

export class XENDMediaTrack {
    title: string;
    album: XENDMediaAlbum;
    artist: XENDMediaArtist;
    artwork: string; // base64 encoded
    length: number;
    number: number;
}

export class XENDMediaCurrentItem {
    track: XENDMediaTrack;
    album: XENDMediaAlbum;
    artist: XENDMediaArtist;
    elapsedDuration: number;
}

export class XENDMediaProperties {
    currentTrack: XENDMediaCurrentItem;
    upcomingTracks: XENDMediaTrack[];

    userArtists: XENDMediaArtist[];
    userAlbums: XENDMediaAlbum[];

    isPlaying: boolean;
    isStopped: boolean;
    isShuffleEnabled: boolean;

    volume: number;
    playingApplication: XENDApplication;
}

export default class XENDMediaProvider extends XENDBaseProvider {

    // NOTE: Don't rely on native layer to push through elapsed time
    // It'll come through on pause/play etc, but should really handle that here
    // to avoid massive communication overhead

    public get data(): XENDMediaProperties {
        return this._data;
    }

    /**
     * Toggles play/pause of the current media item.
     * 
     * Usage:
     * ```
     * WidgetInfo.media.togglePlayState();
     * 
     * // Alternatively:
     * WidgetInfo.media.togglePlayState().then(function(newState) {
     * 
     * });
     * ```
     * @return A promise that resolves with the new play/pause state
     */
    public async togglePlayState(): Promise<boolean> {
        return new Promise<boolean>((resolve, reject) => {
            this.connection.sendNativeMessage({
                namespace: DataProviderUpdateNamespace.Applications,
                functionDefinition: 'togglePlayState',
                data: {}
            }, (newState: boolean) => {
                resolve(newState);
            });
        });
    }
}