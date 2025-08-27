# Antrag

[![GitHub Release](https://img.shields.io/github/v/release/khcrysalis/antrag?include_prereleases)](https://github.com/khcrysalis/protokolle/releases)
[![GitHub License](https://img.shields.io/github/license/khcrysalis/antrag?color=%23C96FAD)](https://github.com/khcrysalis/protokolle/blob/main/LICENSE)

A modern SwiftUI app to manage iOS/iPadOS applications on stock devices. This app uses [idevice](https://github.com/jkcoxson/idevice) and lockdownd pairing to retrieve and manage installed apps.

## ✨ Features

- **Modern SwiftUI Interface** - Built with SwiftUI for iOS 16+ design guidelines and Liquid Glass compatibility
- **Smart App Listing** - View both System and User apps with beautiful app icons
- **Advanced Search** - Real-time search with iOS 16+ native search experience
- **Mass Operations** - Select and delete multiple apps at once
- **App Management** - Delete, open, and view detailed app information
- **Clean Settings** - Streamlined settings with useful options only
- **Auto-refresh** - Configurable automatic app list refreshing
- **Native iOS Experience** - Context menus, sheets, and modern iOS interactions

## 📱 Download

<a href="https://apps.apple.com/us/app/antrag/id6747074491" target="_blank" rel="noopener noreferrer">
    <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" style="width: 200px; height: auto;">
</a>

### Development Builds
Unsigned IPA files are automatically built and released for each commit to the main branch. Check the [Releases](https://github.com/khcrysalis/antrag/releases) page for the latest development builds.

## How does it work?

- Establish a heartbeat with a TCP provider (the app will need this for later).
  - For it to be successful, we need a pairing file from [JitterbugPair](https://github.com/osy/Jitterbug/releases) and a [VPN](https://apps.apple.com/us/app/stosvpn/id6744003051).
- When preparing the list, we need to establish another connection but for `installation_proxy` using our heartbeat provider and client handle.
- Then we can use `installation_proxy_get_apps` using that handle to list applications.

Due to how it works right now we need both a VPN and a lockdownd pairing file, this means you will need a computer for its initial setup.

## Building

#### Minimum requirements

- Xcode 16
- Swift 5.9
- iOS 16

1. Clone repository
    ```sh
    git clone https://github.com/khcrysalis/Antrag
    ```

2. Compile
    ```sh
    cd Antrag
    gmake
    ```

3. Updating
    ```sh
    git pull
    ```

## 🔧 Development

This project has been migrated from UIKit to SwiftUI for better performance, maintainability, and modern iOS compatibility.

### Building

The project uses a Makefile for automated building and packaging:

```bash
# Clean and build unsigned IPA
make clean && make

# The IPA will be available in packages/Antrag.ipa
```

Using the makefile will automatically create an adhoc ipa inside the packages directory. For development and debugging, it's recommended to use Xcode directly.

### GitHub Actions

The project includes automated CI/CD that:
- Builds unsigned IPAs on every push to main/ui-update branches
- Creates automatic releases for main branch commits
- Caches build dependencies for faster builds
- Includes build metadata and file size information

### Architecture

- **SwiftUI** - Modern declarative UI framework
- **MVVM Pattern** - Clean separation of concerns with ViewModels
- **Async/Await** - Modern concurrency for network operations
- **idevice** - Backend framework for iOS device communication

## Sponsors

| Thanks to all my [sponsors](https://github.com/sponsors/khcrysalis)!! |
|:-:|
| <img src="https://raw.githubusercontent.com/khcrysalis/github-sponsor-graph/main/graph.png"> |
| _**"samara is cute" - Vendicated**_ |

## Acknowledgements

- [Samara](https://github.com/khcrysalis) - The maker
- [idevice](https://github.com/jkcoxson/idevice) - Backend functionality, uses `installation_proxy` to retrieve messages.

## License 

This project is licensed under the GPL-3.0 license. You can see the full details of the license [here](https://github.com/khcrysalis/Feather/blob/main/LICENSE). Code from Antoine is going to be under MIT, if you figure out where that is.

By contributing to this project, you agree to license your code under the GPL-3.0 license as well (including agreeing to license exceptions), ensuring that your work, like all other contributions, remains freely accessible and open.
