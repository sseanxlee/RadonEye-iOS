# Changelog

All notable changes to the RadonEye iOS application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-01-XX (Current Development)

### Added
- **Modern SwiftUI Welcome Screen**: Complete redesign with clean, professional interface
- **New App Architecture**: Hybrid SwiftUI/UIKit architecture with modern navigation patterns
- **Enhanced Settings UI**: Redesigned settings with improved button responsiveness and haptic feedback
- **App Store Rating System**: Intelligent rating prompts (5 minutes after first use, weekly reminders)
- **Dark Mode Support**: System-wide dark mode toggle with instant application
- **Improved User Experience**: Seamless transitions between welcome and main app views

### Enhanced
- **Settings Navigation**: All settings buttons now have full-area tap responsiveness with haptic feedback
- **About Us Section**: Modern design with improved typography and better contact information layout
- **Get Help Section**: Streamlined support resources with direct links to documentation and FAQ
- **Feature Request System**: Built-in feature request form with email integration
- **Navigation Flow**: Simplified welcome-to-app navigation using modern SwiftUI patterns

### Fixed
- **Storyboard Dependencies**: Removed legacy storyboard segue from welcome screen to device list
- **Button Responsiveness**: Fixed settings buttons that only responded to arrow taps
- **Navigation Consistency**: Unified navigation patterns across the application

### Removed
- **Unimplemented Features**: Removed placeholder "Device Settings" and "Notifications" from settings
- **Legacy Navigation**: Eliminated outdated storyboard segue dependencies where possible

### Technical Improvements
- **Code Architecture**: Modernized codebase with SwiftUI best practices
- **User Interface**: Consistent design language throughout the application
- **Performance**: Optimized view rendering and navigation transitions
- **Accessibility**: Improved haptic feedback and visual design

## [2.0.0] - Previous Release

### Features
- RadonEye device connectivity and monitoring
- Real-time radon level tracking
- Data logging and export functionality
- Device management and categorization
- Multi-language support (English/Korean)
- Bluetooth Low Energy (BLE) integration

## [1.x.x] - Legacy Versions

### Historical Features
- Basic RadonEye device connectivity
- UIKit-based interface
- Storyboard navigation architecture
- Core monitoring functionality

---

## Development Notes

### Current Architecture Status
- **SwiftUI Integration**: 85% modernized with SwiftUI components
- **Remaining Legacy**: Device monitoring views still use UIKit (planned for future update)
- **Navigation**: Mixed SwiftUI/storyboard navigation (actively being modernized)

### Upcoming Features (Planned)
- [ ] Complete SwiftUI monitoring interface
- [ ] Enhanced data visualization
- [ ] Improved device management
- [ ] Additional customization options
- [ ] Advanced notification system

### Technical Debt
- [ ] Complete migration from storyboard to SwiftUI navigation
- [ ] Modernize remaining UIKit monitoring views
- [ ] Consolidate dual device list implementations
- [ ] Remove remaining legacy view controllers

---

## Contributors
- Development Team
- UI/UX Improvements
- Architecture Modernization

## Support
For technical support or feature requests, please contact: support@ecosense.io
Visit our website: https://ecosense.io
