## Xen HTML
Unified and simplified HTML rendering
=========

Xen HTML provides users the ability to display any HTML-based widget on the Lockscreen and Homescreen of their iOS devices.

### Building

This project requires [iOSOpenDev](https://github.com/Matchstic/iOSOpenDev). Dependant third-party libraries and private headers are included within this repository for portability reasons.

### Branches

The `master` branch is a snapshot of development on each public release.

All development efforts occur in the `develop` branch until they are stable enough for a release.

The `v1.x.y` branch is a legacy branch for Xen HTML 1.x.y, in the event a hotfix is required there.

### Notes for development

Support for different iOS versions is split into multiple dylibs.

The `Loader` subproject manages loading the correct dylib at runtime for the current iOS version. At the time of writing, there are two dylibs generated: `XenHTML_9to12.dylib` and `XenHTML_13.dylib`. It is intended that a new one will be created when either the following are satisfied:

- There has been significant underlying changes in iOS's handling of the Lockscreen or Homescreen
- The most recent dylib already supports 2 major iOS versions

This is to help reduce the chance of regressions breaking previous iOS version support, and also to ease development overhead.

The core of Xen HTML's rendering is handled as a shared (but static) library, linked into each dylib. Any changes here should always be tested on as many versions of iOS as reasonably possible.

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
