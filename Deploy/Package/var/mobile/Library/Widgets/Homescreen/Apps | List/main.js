/**
 * Called when the document has loaded
 */
function onload() {
    // Register an observer for when app data changes
    api.apps.observeData(function(newData) {
        generateDrawer();
    });

    generateDrawer();
}

/**
 * Generates the contents of the app drawer
 */
function generateDrawer() {
    const allApps = api.apps.allApplications;
    const drawerEntries = [];

    for (let i = 0; i < allApps.length; i++) {
        const item = allApps[i];

        let appEntry = document.createElement('div');
        appEntry.className = 'application-entry';
        appEntry.onclick = () => {
            // Open the app
            api.apps.launchApplication(item.identifier);
        };

        // Icon
        let appIcon = document.createElement('img');
        appIcon.src = item.icon;

        appEntry.appendChild(appIcon);

        // Name
        let appName = document.createElement('p');
        appName.innerHTML = item.name;

        appEntry.appendChild(appName);

        // Badge if present
        if (item.badge) {
            let appBadge = document.createElement('div');
            appBadge.innerHTML = item.badge;
            appBadge.className = 'application-badge';

            appEntry.appendChild(appBadge);
        }

        drawerEntries.push(appEntry);
    }

    // Replace contents of #drawerwith the generated children
    let container = document.getElementById('drawer');
    container.innerHTML = '';

    drawerEntries.forEach(function(element) {
        container.appendChild(element);
    });
}