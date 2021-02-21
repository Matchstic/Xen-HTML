/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when calendar data changes
    api.calendar.observeData(function(newData) {
        const hasAnyEvents = newData.upcomingWeekEvents.length > 0;
        
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);
        
        const hasTodayEvent = hasAnyEvents ? newData.upcomingWeekEvents[0].start <= tomorrow.getTime() : false;
        
        // Change layout depending on if any events are upcoming
        if (hasTodayEvent) {
            const nextEvent = newData.upcomingWeekEvents[0];
            
            // Ensure the calendar tint is visible, and set its colour
            document.getElementById('calendar-tint').style.background = nextEvent.calendar.color;
            
            // Set title
            document.getElementById('event-name').innerText = nextEvent.title;
            
            // And also time the event starts
            if (nextEvent.allDay) {
                document.getElementById('event-time').innerText = 'All day';
            } else {
                const formatted = new Date(nextEvent.start).toLocaleTimeString(undefined, {
                    hour: '2-digit', 
                    minute: '2-digit'
                });
                
                document.getElementById('event-time').innerText = formatted;
            }
        } else {
            // Show a 'no events' label
            document.getElementById('event-name').innerText = 'No upcoming events today';
            document.getElementById('calendar-tint').style.background = 'rgb(72, 72, 74)';
        }
        
        // Update header section
        document.getElementById('day-name').innerText =
            new Date().toLocaleDateString(undefined, { weekday: 'long' });
        document.getElementById('day-number').innerText =
            new Date().toLocaleDateString(undefined, { day: 'numeric' });
    });
}