import { XENDBaseProvider } from '../types';

export class XENDWeatherProperties {

}

export default class XENDWeatherProvider extends XENDBaseProvider {

    public get data(): XENDWeatherProperties {
        return this._data;
    }

}