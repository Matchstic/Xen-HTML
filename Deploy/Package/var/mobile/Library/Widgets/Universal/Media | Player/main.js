let scrobbleIsDragging = false;

/**
 * This function is called when the widget finishes loading.
 */
function onload() {
    // Register for media data changes
    api.media.observeData(function (newData) {
        // `newData` is equivalent to `api.media`

        if (newData.isStopped) {
            // Hide details and show no media playing
            document.getElementById('visible-details').style = 'display: none;';
            document.getElementById('no-details').style = 'display: initial;';
        } else {
            // Show details because there is media data available
            document.getElementById('visible-details').style = 'display: initial;';
            document.getElementById('no-details').style = 'display: none;';
        }

        // Set track name and artist info
        document.getElementById('track').innerHTML = newData.nowPlaying.title;
        document.getElementById('artist').innerHTML = newData.nowPlaying.artist;

        // Artwork image
        document.getElementById('artwork').src = newData.nowPlaying.artwork.length > 0 ? newData.nowPlaying.artwork : 'xui://resource/default/media/no-artwork.svg';
        document.getElementById('artwork').className = newData.nowPlaying.artwork.length > 0 ? 'content' : '';

        // Background artwork
        if (newData.nowPlaying.artwork.length > 0) {
            document.getElementById('background-artwork').src = newData.nowPlaying.artwork;
            document.getElementById('background-artwork').style = 'display: initial;';
        } else {
            document.getElementById('background-artwork').style = 'display: none;';
        }

        // Update pause button state
        if (newData.isPlaying) {
            // Show pause button
            document.getElementById('play').style = 'display: none;';
            document.getElementById('pause').style = 'display: initial;';
        } else {
            // Show play button
            document.getElementById('play').style = 'display: initial;';
            document.getElementById('pause').style = 'display: none;';
        }

        // Update volume slider position
        handleVolume(newData.volume);

        // Update elapsed/length state
        handleTrackTimes(newData.nowPlaying.elapsed, newData.nowPlaying.length, false);
        handleScrobblePosition(newData.nowPlaying.elapsed, newData.nowPlaying.length);
    });

    // Elapsed time observer - needed for live updates to the elapsed time shown in the UI
    api.media.observeElapsedTime(function (newElapsedTime) {
        // Call update function with the time, and the same length
        handleTrackTimes(newElapsedTime, api.media.nowPlaying.length, false);
        handleScrobblePosition(newElapsedTime, api.media.nowPlaying.length);
    });

    // Set initial volume slider position
    handleVolume(api.media.volume);
}

/**
 * Handles updating the UI for the given track timings
 * @param {*} elapsed
 * @param {*} length
 */
function handleTrackTimes(elapsed, length, forceUpdate) {
    if (scrobbleIsDragging && !forceUpdate) return;

    const elapsedContent = length === 0 ? '--:--' : secondsToFormatted(elapsed);
    document.getElementById('elapsed').innerHTML = elapsedContent;

    const lengthContent = length === 0 ? '--:--' : secondsToFormatted(length);
    document.getElementById('length').innerHTML = lengthContent;

    // Update the progress bar
    document.getElementById('playback-time').setAttribute('max', length);
    document.getElementById('playback-time').value = elapsed;
}

/**
 * Called seperately from handleTrackTimes to avoid a rescursive loop when dragging the slider
 * @param {*} elapsed
 * @param {*} length
 */
function handleScrobblePosition(elapsed, length) {
    if (scrobbleIsDragging) return;

    const scrobble = document.getElementById('scrobble-slider');
    scrobble.setAttribute('max', length);
    scrobble.value = elapsed;
}

/**
 * Updates the volume slider with the specified level
 * @param {*} level
 */
function handleVolume(level) {
    document.getElementById('volume-slider').setAttribute('value', level);
}

/**
 * Generates a formatted time for the seconds specified
 * @param {*} seconds
 */
function secondsToFormatted(seconds) {
    if (seconds === 0) return '0:00';

    const isNegative = seconds < 0;
    if (isNegative) return '0:00';

    seconds = Math.abs(seconds);
    const hours = Math.floor(seconds / 60 / 60);
    const minutes = Math.floor(seconds / 60) - (hours * 60);
    const secs = Math.floor(seconds - (minutes * 60) - (hours * 60 * 60));

    if (hours > 0) {
        return hours + ':' + (minutes < 10 ? '0' : '') + minutes + ':' + (secs < 10 ? '0' : '') + secs;
    } else {
        return minutes + ':' + (secs < 10 ? '0' : '') + secs;
    }
}

/**
 * Called by the volume slider when the user interacts with it
 * @param {string} input New value
 */
function onVolumeChanged(input) {
    api.media.setVolume(input);
}

/**
 * Called by the scrobble hidden slider whilst the user is interacting with it
 * @param {string} input New value
 */
function onScrobbleUIChanged(input) {
    scrobbleIsDragging = true;

    // Update progress bar only, the scrobble slider is already in position
    handleTrackTimes(input, api.media.nowPlaying.length, true);
}

/**
 * Called by the scrobble hidden slider when the user finishes interacting with it
 * @param {string} input New value
 */
function onScrobbleChanged(input) {
    // Notify API to change the scrobble position, since the user wants to
    // set at this position
    api.media.seekToPosition(input);

    // Update progress bar, the scrobble slider is already in position
    handleTrackTimes(input, api.media.nowPlaying.length, true);

    scrobbleIsDragging = false;
}