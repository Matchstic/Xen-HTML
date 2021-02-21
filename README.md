## Xen HTML
Unified and simplified HTML rendering
=========

Xen HTML provides users the ability to display any HTML-based widget on the Lockscreen and Homescreen of their iOS devices.

### Architecture

Xen HTML is in a weird sort-of-modular setup. Since 2019, all additions are designed as modules, and most existing code is split where it made sense at the time. The following modules exist:

- `Tweak (iOS 9 to 12)` → tweak core for iOS 9 through 12, applying hooks where necessary
- `Tweak (iOS 13)` → tweak core for iOS 13 and 14, applying hooks where necessary
- `Shared` → a statically linked library for code shared between all iOS versions of the tweak core
- `Shared/Configuration` → a sort-of-modular library that handles rendering widget settings
- `Loader` → handles loading the correct version of the tweak core based on iOS version, and also other libraries that depend on load order
- `Helpers/BatteryManager` → a separate tweak that hooks into the core tweak, and handles applying battery management to widgets
- `Helpers/DenyInjection` → a separate tweak that handles preventing other tweaks accidentally injecting into WebKit processes (this was causing freezes for some users)
- `Helpers/WebGL` -→ slightly misnamed, but is a separate tweak which allows rendering widgets in a secure context (the Lockscreen). Originally, this was only needed for WebGL rendering to work.
- `Helpers/WidgetInfo/WidgetInfo` → a tweak wrapping the local process component of `libwidgetinfo`
- `Helpers/WidgetInfo/Daemon` → a daemon process wrapping the remote process component of `libwidgetinfo`
- `Preferences` → settings bundle

### Building

This project requires [iOSOpenDev](https://github.com/Matchstic/iOSOpenDev). Dependant third-party libraries and private headers are included within this repository for portability reasons.

You will also need [node.js](https://nodejs.org/en/) and [yarn](https://yarnpkg.com/) installed to build the widget info library, and the Setup UI.

### Branches

The `master` branch is a snapshot of development on each public release.

All development efforts occur in the `develop` branch until they are stable enough for a release.

The `v1.x.y` branch is a legacy branch for Xen HTML 1.x.y, in the event a hotfix is required there.

### Notes for development

Support for different iOS versions is split into multiple dylibs, as listed in Architecture above.

The `Loader` component manages loading the correct dylib at runtime for the current iOS version. At the time of writing, there are two dylibs generated: `XenHTML_9to12.dylib` and `XenHTML_13.dylib`. It is intended that a new one will be created when either the following are satisfied:

- There has been significant underlying changes in iOS's handling of the Lockscreen or Homescreen
- The most recent dylib already supports 2 major iOS versions

This is to help reduce the chance of regressions breaking previous iOS version support, and also to ease development overhead.

The core of Xen HTML's rendering is handled as a shared (but static) library, linked into each dylib. Any changes here should always be tested on as many versions of iOS as reasonably possible.

The `Loader` component also loads most helper components at runtime, such as `WidgetInfo` and `BatteryManager`. This is to workaround load ordering issues when calling `dlopen` inside a constructor on iOS 14.

Furthermore, its probably a good idea to mention that parts of the codebase are messy when it comes to handling backwards compatibility. This is mainly restricted to handling settings for widgets; dealing with four different approaches lead to some nasty spaghetti code. Additionally, the code for placing widgets directly on the Homescreen is duplicated from its counterpart in `Preferences`.

#### Build instructions

As noted above, make sure you have Xcode + iOSOpenDev setup before trying to build.

- To build the project, click Product -> Build, or use `⌘ + B`
- A new package can be generated using Product -> Build for... -> Profiling, or use `⌘ + shift + I`, whilst the `Deploy` target is selected on the top left
- Incrementing version number is done by updating `./Deploy/PackageVersion.plist`, and then creating a new package as above

You can individually build each component of the project, and can individually deploy them to the Simulator. To do this, make sure to:

0. Ensure `simject` is installed and running as part of iOSOpenDev
1. Set the `SIMJECT` flag to `YES` in the relevant component's settings (in their associated `.xcodeproj` file)
2. Toggle the codebase to use the internal theos generator, which is just uncommenting the relevant line at the top of the `.xm` file for the component
3. Switch the target at the top left of Xcode to the component you want to build
4. Make sure a Simulator instance is running for the device + iOS version you want to test against
5. Hit `⌘ + B` to build and deploy; the Simulator instance will automatically respring for you

You will probably notice a *lot* of warnings emitted during the build phase. The majority of this is linker complaints about dependant third-party libraries being linked, and for code-signing which appear safe to ignore.

#### Simulation

As mentioned, Xen HTML can be run in the iOS simulator. To load widgets in this mode, manually copy them to `/opt/simject`, treating that directory as `/`. As an example, widgets can be installed to `/opt/simject/var/mobile/Library/Widgets/Universal`.

Translations don't work in this mode, nor does the setup UI experience.

### Future plans

As part of a modernisation project, the following are ideas to be built at some point:

- [ ] An integrated widget info library, providing full backwards compatibility for all previous libraries
- [ ] A desktop widget simulator (most likely written in Electron for portability)
- ???

#### Want to help out?

This project needs to be moved over to `theos` for those without iOSOpenDev, and there's a few enhancements waiting in the Issues tab.

#### Contributions

Please create a pull request to this repository if you make any improvements to the tweak; releasing as an update on a seperate repository will cause too much fragmentation!

### License

Licensed under the GPLv2. Note: any widget ran using Xen HTML is not treated as derivative work. 

#### Third Party Libraries

[AYVibrantButton](https://github.com/a1anyip/AYVibrantButton) is utilised in the Preference bundle.
