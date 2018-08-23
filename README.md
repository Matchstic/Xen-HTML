## Xen HTML
Unified and simplified HTML rendering
=========

Xen HTML provides users the ability to display any HTML-based widget on the Lockscreen and Homescreen of their iOS devices.

### Remaining Issues

- [x] Add proper localisation support throughout the tweak and preferences
- [x] Work out which feature enhancements should be taken through into v1.0

### Building

This project requires iOSOpenDev. Dependant third-party libraries and private headers are included within this repository for portability reasons.

### Notes for development

`XenHTML.xm` is rather horrendous; its got too many headers inline, and all modifications in SpringBoard are contained within the same file. Sorry about that.

#### Want to help out?

This project needs to be moved over to `theos` for those without iOSOpenDev, and there's a few enhancements waiting in the Issues tab.

#### Contributions

Please create a pull request to this repository if you make any improvements to the tweak; releasing as an update on a seperate repository will cause too much fragmentation!

### License

Licensed under the GPLv2. Note: any widget ran using Xen HTML is not treated as derivative work. 

#### Third Party Libraries

[AYVibrantButton](https://github.com/a1anyip/AYVibrantButton) is utilised in the Preference bundle.
