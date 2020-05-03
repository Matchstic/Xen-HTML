/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when system data changes
    api.resources.observeData(function(newData) {
        // Update icon
        let iconElement = document.getElementById('battery-icon');

        if (newData.battery.percentage === 100) {
            iconElement.src = 'xui://resource/default/battery/100.svg';
        } else if (newData.battery.percentage >= 90) {
            iconElement.src = 'xui://resource/default/battery/90.svg';
        } else if (newData.battery.percentage >= 80) {
            iconElement.src = 'xui://resource/default/battery/80.svg';
        } else if (newData.battery.percentage >= 70) {
            iconElement.src = 'xui://resource/default/battery/70.svg';
        } else if (newData.battery.percentage >= 60) {
            iconElement.src = 'xui://resource/default/battery/60.svg';
        } else if (newData.battery.percentage >= 50) {
            iconElement.src = 'xui://resource/default/battery/50.svg';
        } else if (newData.battery.percentage >= 40) {
            iconElement.src = 'xui://resource/default/battery/40.svg';
        } else if (newData.battery.percentage >= 30) {
            iconElement.src = 'xui://resource/default/battery/30.svg';
        } else if (newData.battery.percentage >= 20) {
            iconElement.src = 'xui://resource/default/battery/20.svg';
        } else if (newData.battery.percentage >= 10) {
            iconElement.src = 'xui://resource/default/battery/10.svg';
        } else {
            iconElement.src = 'xui://resource/default/battery/0.svg';
        }

        // Generate text to display underneath the current percent
        let underneathText = '';
        if (newData.battery.state === 2) {
            underneathText = 'Fully charged';
        } else if (newData.battery.state === 1) {
            underneathText = 'Charged in: ' + minutesToHumanReadable(newData.battery.timeUntilCharged);
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