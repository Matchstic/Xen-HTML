import { XENDBaseProvider } from '../types';

export class XENDCalendarEntry {
    title: string;
    location: string;
    allDay: boolean;
    startTimestamp: number;
    endTimestamp: number;
    calendar: XENDCalendar;
}

export class XENDCalendar {
    name: string;
    identifier: string;
    hexColor: string;
}

export class XENDCalendarProperties {
    userCalendars: XENDCalendar[];
    upcomingWeekEvents: XENDCalendarEntry[];
}

export default class XENDCalendarProvider extends XENDBaseProvider {

    public get data(): XENDCalendarProperties {
        return this._data;
    }

    /**
     * 
     * @param startTimestamp 
     * @param endTimestamp 
     * @param calendars 
     */
    public async fetchEntries(startTimestamp: number, endTimestamp?: number, 
                              calendars?: XENDCalendar[]): Promise<XENDCalendarEntry[]> {
        return new Promise<XENDCalendarEntry[]>((resolve, reject) => {
            resolve([]);
        });
    }
}