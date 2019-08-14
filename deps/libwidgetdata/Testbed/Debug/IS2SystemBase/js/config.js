///////////////////////////////////////////////////////////////////////////////////
// Variables.
// You only need to edit these! Please don't touch anything else in here.

var widgetIdentifier = "changeme"; // Used to uniquely identify your widget to IS2.
var plistPath = "/var/mobile/Library/Preferences/changeme.plist"; // Allows you to load in values from a preferences plist file.

///////////////////////////////////////////////////////////////////////////////////
// Helper functions - don't edit!

var standalone = window.navigator.standalone,
    userAgent = window.navigator.userAgent.toLowerCase(),
    safari = /safari/.test( userAgent ),
    ios = /iphone|ipod|ipad/.test( userAgent );
    
var is2Available = false;

if(ios && !standalone && !safari ) {
  if (window.indexedDB) {
    // Running in a WKWebView, currently unsupported.
  } else {
    // UIWebView
    is2Available = true;
  }        
}

// Used to ensure we correctly unload callbacks after your widget disappears.
if (is2Available) {
  window.onunload = function() {
    IS2Alarms.onunload();
    IS2Calendar.onunload();
    IS2Location.onunload();
    IS2Media.onunload();
    IS2Notifications.onunload();
    IS2Pedometer.onunload();
    IS2Telephony.onunload();
    IS2Weather.onunload();
  
    return null;
  };
}

///////////////////////////////////////////////////////////////////////////////////
// Handle fallbacks for when running in a browser that is not supported by IS2.
// Typically, the "text/cycript" tags will be completely ignored, and nothing will happen.

if (!is2Available) {
  var IS2Alarms = {
  
  };
  var IS2Calendar = {
  
  };
  var IS2Location = {
  
  };
  var IS2Media = {
    init: function(mediaChangedCallback, timeElapsedChangedCallback) {},
    onunload: function() {},
    play: function() {},
    pause: function() {},
    previousTrack: function() {},
    nextTrack: function() {},
    setVolume: function(percentage, showHUD) {},
    getTrackTitle: function() { return "Test Track"; },
    getTrackArtist: function() { return "Test Artist"; },
    getTrackAlbum: function() { return "Test Album"; },
    getTrackArtworkBase64String: function() { return "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="; },
    getTrackLength: function() { return 250; },
    getTrackElapsedTime: function() { return 100; },
    getTrackNumber: function() { return 1; },
    getTrackCountInAlbum: function() { return 10; },
    getNowPlayingAppIdentifier: function() { return "com.apple.Music"; },
    getIsPlaying: function() { return true; },
    getIsShuffleEnabled: function() { return false; },
    getIsPlayingFromItunesRadio: function() { return false; },
    getIsTrackAvailable: function() { return true; },
    getVolumeLevel: function() { return 0.5; }
  };
  var IS2Notifications = {
  
  };
  var IS2Pedometer = {
  
  };
  var IS2PlistPreferences = {
  
  };
  var IS2Telephony = {
  
  };
  var IS2Weather = {
    init: function(weatherUpdatedCallback, updateTimeInterval) {},
    onunload : function() {},
    getIsCelsius: function() { return true; },
    getIsWindSpeedMPH: function() { return true; },
    getLocation: function() { return "Cupertino"; },
    getLatitude: function() { return 37.323; },
    getLongitude: function() { return -122.0322; },
    getTemperature: function() { return 25; },
    getConditionCode: function() { return 34; },
    getConditionCodeAsString: function() { return "Mostly Sunny"; },
    getDescriptionOfCondition: function() { return "Mostly sunny, currently 25°C with a high of 30°C and low of 17°C."; },
    getHigh: function() { return 30; },
    getLow: function() { return 17; },
    getWindSpeed: function() { return 5; },
    getWindDirectionAsCardinal: function() { return 175; },
    getWindChill: function() { return 24; },
    getDewPoint: function() { return 6; },
    getHumidity: function() { return 67; },
    getCurrentVisibilityInPercent: function() { return 96; },
    getChanceOfRain: function() { return 10; },
    getFeelsLike: function() { return 24; },
    getPressureInMillibars: function() { return 1020; },
    getSunsetTime: function() { return "18:32"; },
    getSunriseTime: function() { return "5:34"; },
    getHourlyForecastsArray: function() { return JSON.parse("[{\"time\": \"15:00\",\"condition\": 30,\"temperature\": 24,\"percentPrecipitation\": 30}, {\"time\": \"16:00\",\"condition\": 34,\"temperature\": 23,\"percentPrecipitation\": 20}, {\"time\": \"17:00\",\"condition\": 34,\"temperature\": 23,\"percentPrecipitation\": 30}, {\"time\": \"18:00\",\"condition\": 30,\"temperature\": 23,\"percentPrecipitation\": 30}]"); },
    getDailyForecastsArray: function() { return JSON.parse("[{\"dayNumber\": 1,\"dayOfWeek\": 3,\"condition\": 30,\"high\": 26,\"low\": 20},{\"dayNumber\": 2,\"dayOfWeek\": 4,\"condition\": 34,\"high\": 27,\"low\": 21},{\"dayNumber\": 3,\"dayOfWeek\": 5,\"condition\": 28,\"high\": 23,\"low\": 17},{\"dayNumber\": 4,\"dayOfWeek\": 6,\"condition\": 40,\"high\": 20,\"low\": 16}]"); }
  };
}