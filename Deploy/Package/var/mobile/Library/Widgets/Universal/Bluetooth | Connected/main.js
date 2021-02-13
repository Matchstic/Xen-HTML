/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when communications data changes
    api.comms.observeData(function(newData) {        
        updateDevices(newData);
    });
}

/**
 * Generates device list elements
 */
function updateDevices(data) {
    const clearContainer = () => {
        // Reset contents of #container
        const container = document.getElementById('container');
        container.innerHTML = '';
    };
    
    if (data.bluetooth.devices.length > 0) {
        // Create the device items
        const deviceElements = [];
        data.bluetooth.devices.forEach((device) => {
            const element = document.createElement('div');
            element.className = 'device-item';
        
            const name = document.createElement('p');
            name.innerText = device.name;
            name.className = 'device-name';
        
            const icon = document.createElement('img');
            icon.src = 'img/' + (device.majorClass === 1024 ? 'headphones.png' : 'bluetooth-small.png');
        
            const battery = document.createElement('p');
            battery.innerText = device.supportsBattery ? 'Battery: ' + device.battery + '%' : 'No battery data';
        
            const block = document.createElement('div');
            block.className = 'device-inner';
        
            block.appendChild(name);
            block.appendChild(battery);
        
            element.appendChild(icon);
            element.appendChild(block);
        
            deviceElements.push(element);
        });
    
        // Ensure there are max 3 items
        if (deviceElements.length > 3)
            deviceElements = deviceElements.slice(0, 3);
        else if (deviceElements.length < 3) {                
            
            // Insert false elements
            const emptyCount = 3 - deviceElements.length
            for (let i = 0; i < emptyCount; i++) {
                const element = document.createElement('div');
                element.className = 'device-item';
                
                const empty = document.createElement('div');
                empty.className = 'device-item-empty';
                
                element.appendChild(empty);
                deviceElements.push(element);
            }
        }
        
        clearContainer();
        
        // Insert new device elements
        deviceElements.forEach((element) => {
            container.appendChild(element);
        });
        
        // Hide empty background
        document.getElementById('empty-background').style.display = 'none';
    } else {
        // Insert label stating Bluetooth state
        clearContainer();
        
        const status = document.createElement('h4');
        status.innerText = data.bluetooth.enabled ? 'No devices connected' : 'Bluetooth is turned off';
        status.className = 'empty-text';
        
        container.appendChild(status);
        
        // Show empty background
        document.getElementById('empty-background').style.display = 'initial';
    }
}