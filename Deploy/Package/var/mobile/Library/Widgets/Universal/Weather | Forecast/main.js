/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when weather data changes
    api.weather.observeData(function(newData) {
        document.getElementById('city').innerText = newData.metadata.address.city;

        document.getElementById('high').innerText = newData.now.temperature.maximum;
        document.getElementById('low').innerText = newData.now.temperature.minimum;

        document.getElementById('narrative').innerText = newData.now.condition.narrative;

        updateForecasts(newData);
    });

    api.system.observeData(function(newData) {
        // Refresh forecasts in case 24-hour time state has changed
        updateForecasts(api.weather);
    });
}

/**
 * Generates hourly forecast elements
 */
function updateForecasts(data) {
    // Create the now element first
    let nowElement;
    {
        nowElement = document.createElement('div');
        nowElement.className = 'forecast-item now';

        let nowHeader = document.createElement('p');
        nowHeader.innerText = 'Now';
        nowHeader.className = 'forecast-item-header now';
        nowElement.appendChild(nowHeader);

        let nowPrecip = document.createElement('p');
        nowPrecip.innerText = data.now.precipitation.hourly > 0 ? data.now.precipitation.hourly + '%' : '';
        nowPrecip.className = 'forecast-item-precip';
        nowElement.appendChild(nowPrecip);

        // Set image from the default resource pack
        let nowImage = document.createElement('img');
        nowImage.src = 'xui://resource/default/weather/' + data.now.condition.code + '.svg';
        nowElement.appendChild(nowImage);

        let nowTemperature = document.createElement('p');
        nowTemperature.innerText = '' + data.now.temperature.current;
        nowTemperature.className = 'forecast-item-temperature';
        nowElement.appendChild(nowTemperature);
    }

    // Create the hourly items
    let hourlyForecasts = [];
    for (let i = 0; i < data.hourly.length; i++) {
        const hour = data.hourly[i];

        let element = document.createElement('div');
        element.className = 'forecast-item';

        let header = document.createElement('p');
        header.innerText = hour.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        header.className = 'forecast-item-header';
        element.appendChild(header);

        let precip = document.createElement('p');
        precip.innerText = hour.precipitation.probability > 0 ? hour.precipitation.probability + '%' : '';
        precip.className = 'forecast-item-precip';
        element.appendChild(precip);

        // Set image from the default resource pack
        let image = document.createElement('img');
        image.src = 'xui://resource/default/weather/' + hour.condition.code + '.svg';
        element.appendChild(image);

        let temperature = document.createElement('p');
        temperature.innerText = '' + hour.temperature.forecast;
        temperature.className = 'forecast-item-temperature';
        element.appendChild(temperature);

        hourlyForecasts.push(element);
    }

    // Replace contents of #forecast-container with the generated children
    let container = document.getElementById('forecast-container');
    container.innerHTML = '';

    // Append now element
    container.appendChild(nowElement);

    // And now for the forecasts
    hourlyForecasts.forEach(function(element) {
        container.appendChild(element);
    });
}