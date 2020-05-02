/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when system data changes
    api.resources.observeData(function(newData) {
        // Update icon
        let iconElement = document.getElementById('battery-icon');

        if (newData.battery.percentage === 100) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 90) {
            iconElement.src = 'images/Battery90.svg';
        } else if (newData.battery.percentage >= 80) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 70) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 60) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 50) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 40) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 30) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 20) {
            iconElement.src = 'images/Battery100.svg';
        } else if (newData.battery.percentage >= 10) {
            iconElement.src = 'images/Battery100.svg';
        } else {
            iconElement.src = 'images/Battery0.svg';
        }

        // Generate text to display underneath the current percent
        let underneathText = '';
        if (newData.battery.state === 2) {
            underneathText = 'Fully charged';
        } else if (newData.battery.state === 1) {
            underneathText = 'Charged in: ' + minutesToHumanReadable(newData.battery.timeUntilCharged);
        } else {
            underneathText = 'Usage left: ' + minutesToHumanReadable(newData.battery.timeUntilEmpty);
        }

        document.getElementById('info').innerHTML = underneathText;
    });
}

function minutesToHumanReadable(mins) {
    if (mins <= 0) return '<span class="missing">No information</span>';

    let hours = Math.floor(mins / 60);
    let reducedMins = mins - (hours * 60);

    if (hours > 0) {
        return hours + ' hour' + (hours === 1 ? '' : 's') + ', ' + reducedMins + ' minute' + (reducedMins === 1 ? '' : 's');
    } else {
        return reducedMins + ' minute' + (reducedMins === 1 ? '' : 's');
    }
}