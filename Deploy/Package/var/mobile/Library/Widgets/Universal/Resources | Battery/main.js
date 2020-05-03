/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when system data changes
    api.resources.observeData(function(newData) {
        // Update icon
        let iconElement = document.getElementById('battery-icon');

        if (newData.battery.percentage >= 95) {
            iconElement.src = 'xui://resource/default/battery/100.svg';
        } else if (newData.battery.percentage >= 85) {
            iconElement.src = 'xui://resource/default/battery/90.svg';
        } else if (newData.battery.percentage >= 75) {
            iconElement.src = 'xui://resource/default/battery/80.svg';
        } else if (newData.battery.percentage >= 65) {
            iconElement.src = 'xui://resource/default/battery/70.svg';
        } else if (newData.battery.percentage >= 55) {
            iconElement.src = 'xui://resource/default/battery/60.svg';
        } else if (newData.battery.percentage >= 45) {
            iconElement.src = 'xui://resource/default/battery/50.svg';
        } else if (newData.battery.percentage >= 35) {
            iconElement.src = 'xui://resource/default/battery/40.svg';
        } else if (newData.battery.percentage >= 25) {
            iconElement.src = 'xui://resource/default/battery/30.svg';
        } else if (newData.battery.percentage >= 15) {
            iconElement.src = 'xui://resource/default/battery/20.svg';
        } else if (newData.battery.percentage >= 5) {
            iconElement.src = 'xui://resource/default/battery/10.svg';
        } else {
            iconElement.src = 'xui://resource/default/battery/0.svg';
        }

        // Generate text to display underneath the current percent
        let underneathText = '';
        if (newData.battery.state === 2) {
            underneathText = 'Fully charged';
        } else if (newData.battery.state === 1) {
            underneathText = 'Battery charging';
        } else {
            underneathText = 'Estimated time left: ' + minutesToHumanReadable(newData.battery.timeUntilEmpty);
        }

        document.getElementById('info').innerHTML = underneathText;
    });
}

function minutesToHumanReadable(mins) {
    if (mins <= 0) return '<span class="missing">No information</span>';

    let hours = Math.floor(mins / 60);
    let reducedMins = Math.floor(mins - (hours * 60));

    if (hours > 0) {
        return hours + ' hr' + (hours === 1 ? '' : 's') + ', ' + reducedMins + ' min' + (reducedMins === 1 ? '' : 's');
    } else {
        return reducedMins + ' minute' + (reducedMins === 1 ? '' : 's');
    }
}