# RadonEye iOS App

A professional iOS application for monitoring RadonEye devices and tracking radon levels in real-time.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Enabled-green.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)

## 🌟 Features

### 📱 Modern User Interface
- **SwiftUI-first Design**: Clean, modern interface with native iOS design patterns
- **Dark Mode Support**: Full system-wide dark mode with instant switching
- **Responsive Layout**: Optimized for all iPhone sizes and orientations

### 🔗 Device Connectivity
- **Bluetooth Low Energy**: Seamless connection to RadonEye devices
- **Real-time Monitoring**: Live radon level tracking and alerts
- **Device Management**: Organize and categorize multiple RadonEye devices

### 📊 Data & Analytics
- **Real-time Charts**: Live data visualization with Charts framework
- **Data Export**: Export measurement data to CSV format
- **Historical Tracking**: Long-term radon level monitoring and trends

### ⚙️ Professional Features
- **Multi-language Support**: English and Korean localization
- **App Store Integration**: Built-in rating system and user feedback
- **Professional Settings**: Comprehensive configuration options

## 🏗️ Architecture

### Modern Hybrid Architecture
- **SwiftUI Components**: Modern views and navigation (85% complete)
- **UIKit Integration**: Legacy monitoring views (planned for modernization)
- **Core Bluetooth**: BLE device communication
- **Combine Framework**: Reactive data flow

### Key Components
```
├── SwiftUI Views/
│   ├── WelcomeView.swift          # Modern welcome screen
│   ├── DeviceListView.swift       # Device discovery & management
│   ├── SavedDataChartView.swift   # Data visualization
│   └── Settings/                  # Modern settings interface
├── UIKit Views/
│   ├── viewTabTop.swift          # Monitoring interface (legacy)
│   └── viewDeviceList.swift      # Legacy device list
├── BLE/
│   ├── BLEControl.swift          # Bluetooth management
│   └── Scanner/                  # Device discovery
└── Util/
    ├── DeviceNameManager.swift   # Device naming
    └── SavedDataManager.swift    # Data persistence
```

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+**
- **iOS 15.0+** deployment target
- **Swift 5.7+**
- **CocoaPods** for dependency management

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/[username]/RadonEye-iOS.git
   cd RadonEye-iOS
   ```

2. **Install dependencies**
   ```bash
   cd "RadonEye V2"
   pod install
   ```

3. **Open in Xcode**
   ```bash
   open "RadonEye V2.xcworkspace"
   ```

4. **Build and run**
   - Select target device or simulator
   - Press `Cmd+R` to build and run

### Configuration

1. **Firebase Setup** (if required)
   - Add your `GoogleService-Info.plist` to the project
   - Configure Firebase settings as needed

2. **Bluetooth Permissions**
   - Ensure Bluetooth permissions are configured in `Info.plist`
   - Test with physical device for BLE functionality

## 📖 Usage

### First Launch
1. **Welcome Screen**: Choose between modern or classic interface
2. **Device Discovery**: Scan for nearby RadonEye devices
3. **Device Connection**: Select and connect to your RadonEye device
4. **Real-time Monitoring**: View live radon measurements

### Data Management
- **Export Data**: Tap the export icon to save data as CSV
- **View Charts**: Access detailed charts and analytics
- **Manage Devices**: Rename and categorize your devices

### Settings
- **Dark Mode**: Toggle between light and dark themes
- **About Us**: Company information and support links
- **Get Help**: Access documentation and FAQ
- **Feature Requests**: Submit feedback and feature ideas

## 🛠️ Development

### Project Structure
```
RadonEye V2/
├── RadonEye V2/              # Main app source
│   ├── View/                 # SwiftUI and UIKit views
│   ├── BLE/                  # Bluetooth communication
│   ├── Util/                 # Utility classes and managers
│   ├── Charts/               # Data visualization
│   └── Assets.xcassets/      # App icons and images
├── Pods/                     # CocoaPods dependencies
└── RadonEye V2.xcworkspace   # Xcode workspace
```

### Dependencies
- **Charts**: Data visualization framework
- **SideMenu**: Navigation drawer component
- **XLPagerTabStrip**: Tab navigation for monitoring views

### Code Style
- **SwiftUI preferred** for new views and components
- **Combine** for reactive programming patterns
- **MVVM architecture** where applicable
- **Consistent naming conventions** following Swift guidelines

## 🔄 Recent Updates

### Version 2.1.0 (Current)
- ✅ Modern SwiftUI welcome screen
- ✅ Enhanced settings with haptic feedback
- ✅ Removed legacy storyboard dependencies
- ✅ Improved dark mode support
- ✅ App Store rating integration

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## 🤝 Contributing

### Development Guidelines
1. **SwiftUI First**: Use SwiftUI for new views and components
2. **Consistent Design**: Follow existing design patterns and styling
3. **Code Quality**: Maintain clean, readable, and well-documented code
4. **Testing**: Test on physical devices for Bluetooth functionality

### Planned Improvements
- [ ] Complete SwiftUI migration for monitoring views
- [ ] Enhanced data visualization features
- [ ] Improved device management capabilities
- [ ] Advanced notification system

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

- **Email**: support@ecosense.io
- **Website**: [ecosense.io](https://ecosense.io)
- **Documentation**: [RadonEye Quick Guide](https://link.ecosense.io/rd200-guide)
- **FAQ**: [Frequently Asked Questions](https://ecosense.io/pages/rd200-faq-en)

## 🏢 About Ecosense

Ecosense delivers peace of mind through intelligent, highly accurate radon detection technology for homes, schools, assisted living facilities, and commercial buildings. Our patented ion chamber sensors combined with advanced processing software provide the industry's first accurate radon readings in minutes—not days.

---

**Made with ❤️ by the Ecosense Team**