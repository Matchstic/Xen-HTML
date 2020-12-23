## Xen HTML
Unified and simplified HTML rendering
=========

Xen HTML provides users the ability to display any HTML-based widget on the Lockscreen and Homescreen of their iOS devices.

### Building

This project requires [iOSOpenDev](https://github.com/Matchstic/iOSOpenDev). Dependant third-party libraries and private headers are included within this repository for portability reasons.

You will also need [node.js](https://nodejs.org/en/) and [yarn](https://yarnpkg.com/) installed to build the widget info library, and the Setup UI.

### Branches

The `master` branch is a snapshot of development on each public release.

All development efforts occur in the `develop` branch until they are stable enough for a release.

The `v1.x.y` branch is a legacy branch for Xen HTML 1.x.y, in the event a hotfix is required there.

### Notes for development

Support for different iOS versions is split into multiple dylibs.

The `Loader` component manages loading the correct dylib at runtime for the current iOS version. At the time of writing, there are two dylibs generated: `XenHTML_9to12.dylib` and `XenHTML_13.dylib`. It is intended that a new one will be created when either the following are satisfied:

- There has been significant underlying changes in iOS's handling of the Lockscreen or Homescreen
- The most recent dylib already supports 2 major iOS versions

This is to help reduce the chance of regressions breaking previous iOS version support, and also to ease development overhead.

The core of Xen HTML's rendering is handled as a shared (but static) library, linked into each dylib. Any changes here should always be tested on as many versions of iOS as reasonably possible.

The `Loader` component also loads most helper components at runtime, such as `WidgetInfo` and `BatteryManager`. This is to workaround load ordering issues when calling `dlopen` inside a constructor on iOS 14.

You will need to use the Xcode 11 toolchain for development at the time of writing, otherwise arm64e slices that are generated will be backwards incompatible on iOS 13 and lower. See: https://github.com/nahtedetihw/Xcode11Toolchain, or download a copy of Xcode 11 from Apple and just use that.

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

As part of a modernisation project, the following are going to be built at some point:

- [ ] An integrated widget info library, providing full backwards compatibility for all previous libraries
- [ ] A desktop widget simulator (most likely written in Electron for portability)
- [ ] Revisions to where widgets are installed to on the filesystem
- [ ] Improvements to widget settings for developers
- ???

#### Want to help out?

This project needs to be moved over to `theos` for those without iOSOpenDev, and there's a few enhancements waiting in the Issues tab.

#### Contributions

Please create a pull request to this repository if you make any improvements to the tweak; releasing as an update on a seperate repository will cause too much fragmentation!

### License

Licensed under the GPLv2. Note: any widget ran using Xen HTML is not treated as derivative work. 

#### Third Party Libraries

[AYVibrantButton](https://github.com/a1anyip/AYVibrantButton) is utilised in the Preference bundle.
