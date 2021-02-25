/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when reminder data changes
    api.reminders.observeData(function(newData) {
        
        // Ask for completed reminders in the last hour, so we can show them at the top of the widget.
        // This isn't necessary, but is a nice-to-have for when a user taps a reminder to mark it
        // as read, since they'll then stay around for an hour to undo the 'completed' state if needed.
        const oneHour = 60 * 60 * 1000;
        api.reminders.fetch(Date.now() - oneHour, Date.now(), true).then((completed) => {
            try {
                updateReminders(newData.pending, completed);
            } catch (e) {
                console.log(e)
            }
            
        });
        
    });
}

/**
 * Generates a list of completed and pending reminders
 */
function updateReminders(pending, completed) {
    const clearContainer = () => {
        const container = document.getElementById('container');
        container.innerHTML = '';
    };
    
    const priorityToString = (priority) => {
        switch (priority) {
            case 1:
                return '!';
            case 2:
                return '!!';
            case 3:
                return '!!!';
            case 0:
            default:
                return '';
        }
    }
    
    const createRow = (reminder) => {
        const base = document.createElement('div');
        base.className = 'reminder-item';
        
        base.onclick = function() { updateReminder(reminder); };
        
        // Left 'icon' for if done or not
        const toggle = document.createElement('div');
        toggle.className = 'reminder-item-toggle ' + (reminder.completed ? 'completed' : 'pending');
        
        base.appendChild(toggle);
        
        // Main content
        const block = document.createElement('div');
        block.className = 'reminder-item-inner';
        
        // Title and priority
        const title = document.createElement('p');
        let innerHTML = '';
        
        if (reminder.priority > 0) {
            innerHTML = '<span class="priority">' + priorityToString(reminder.priority) + '</span>';
        }
        
        title.innerHTML = innerHTML + reminder.title;
        title.className = 'reminder-item-title';
        
        block.appendChild(title);
        
        // Due date, if available
        if (reminder.due !== -1) {
            const subtitle = document.createElement('p');
            if (reminder.overdue) {
                subtitle.className = 'overdue';
            }
            
            // If the due date is today, show the time
            // Otherwise, show the day
            const dueDate = new Date(reminder.due);
            const todayStart = new Date();
            todayStart.setHours(0, 0, 0, 0);
            
            if (todayStart.getTime() <= dueDate.getTime()) {
                subtitle.innerText = dueDate.toLocaleTimeString(undefined, {
                    hour: '2-digit', 
                    minute: '2-digit'
                });
            } else {
                subtitle.innerText = dueDate.toLocaleDateString(undefined, {
                    year: '2-digit', 
                    month: '2-digit', 
                    day: '2-digit'
                });
            }            
            
            block.appendChild(subtitle);
        }    
        
        base.appendChild(block);
        
        return base;
    };
    
    const createEmptyRow = () => {
        const base = document.createElement('div');
        base.className = 'reminder-item';
        
        const inner = document.createElement('div');
        inner.className = 'reminder-item-empty';
        
        base.appendChild(inner);
        
        return base;
    }
    
    const createTooManyRow = (extraCount) => {
        const base = document.createElement('div');
        base.className = 'reminder-item overflowed';
        
        base.onclick = function() { openApp(); };
        
        const label = document.createElement('p');
        label.className = 'reminder-item-overflow-label';
        label.innerText = extraCount + ' more reminder' + (extraCount > 1 ? 's' : '');
        
        base.appendChild(label);
        
        return base;
    }
    
    // We display up to 3 reminders, but if theres more, the final row is
    // replaced with a message saying there are more for today.
    const maxRows = 3;
    const combinedReminders = completed.concat(pending);
    
    // Different UI state if there is reminders, or not
    if (combinedReminders.length > 0) {
        const sliced = combinedReminders.slice(0, maxRows);
        const hasTooManyToDisplay = combinedReminders.length > maxRows;
    
        // Create all the rows possible
        const rows = [];
        for (let i = 0; i < (hasTooManyToDisplay ? maxRows - 1 : sliced.length); i++) {
            rows.push(createRow(sliced[i]));
        }
    
        // Insert the 'too many' row if needed
        if (hasTooManyToDisplay) {
            rows.push(createTooManyRow(combinedReminders.length - maxRows + 1));
        }
        
        // If there is not maxRows items, insert empty ones
        if (sliced.length < maxRows) {
            for (let i = 0; i < maxRows - sliced.length; i++) {
                rows.push(createEmptyRow());
            }
        }
    
        // Clear container and add the rows
        clearContainer();
        
        const container = document.getElementById('container');
        rows.forEach(function(element) {
            container.appendChild(element);
        });
    } else {
        // Add 'no reminders' message instead        
        const label = document.createElement('p');
        label.innerText = 'No pending reminders';
        label.className = 'empty-text';
        
        container.appendChild(label);
    }
}

/**
 * Inverts the completed state for the reminder
 */
function updateReminder(reminder) {
    api.reminders.update(reminder.id, !reminder.completed);
}

/**
 * Launches the Reminders app to show all
 */
function openApp() {
    api.apps.launchApplication('com.apple.reminders');
}
