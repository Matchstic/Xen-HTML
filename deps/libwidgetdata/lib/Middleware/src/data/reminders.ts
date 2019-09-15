import { XENDBaseProvider } from '../types';

export class XENDRemindersProperties {
    
}

export default class XENDRemindersProvider extends XENDBaseProvider {

    public get data(): XENDRemindersProperties {
        return this._data;
    }

}