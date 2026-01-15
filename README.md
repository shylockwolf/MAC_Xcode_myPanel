# myPanel

Version: 2.0.1

## Overview

myPanel is a lightweight macOS application built with SwiftUI designed to manage and access frequently used files and applications through a simple panel interface. Users can quickly select and open their frequently used files with a clean and intuitive UI.

## Features

- Quick file and application access panel (9 slots)
- Persistent storage of last opened files
- Customizable preferences (theme and language)
- Support for both regular files and .app applications
- File/application icon display for each item
- Individual item clear/reset functionality
- Global reset functionality to clear all configuration
- Clean and intuitive user interface with consistent layout
- Version information display

## Changelog

### Version 2.0.1

#### New Features
- Updated version number to 2.0.1
- Updated creation date to 2026-01-15

### Version 2.0.0

#### New Features
- Changed button icon from "doc.circle.fill" to "play.circle" with blue color
- Simplified button click handling to directly open files
- Optimized button disabled logic using selectedFiles array

### Version 1.7

#### New Features
- Added individual clear button for each file item (X icon in red)
- Added file/application icon display between button and file name
- Updated application icon with new design

#### Improvements
- Optimized button size for better layout balance
- Unified element heights (32px) for consistent visual alignment
- Updated project documentation to reflect SwiftUI technology stack
- Unified version numbering across all files to 1.7
- Fixed inconsistency in element count (6 vs 9) in reset and load functions
- Updated creation date to 2026-01-07

### Version 1.6

#### New Features
- Added reset button for clearing all configuration and resetting application state
- Updated UI with version, author, and creation date information in the top-right corner

#### Bug Fixes
- Fixed unreachable catch block warning in file opening functionality
- Resolved compilation errors related to API usage

#### Improvements
- Optimized UI layout with better information organization
- Enhanced user interaction with confirmation dialog for reset action

### Version 1.5

#### New Features
- Enhanced UI with improved visual hierarchy
- Better error handling for file operations
- Improved configuration loading mechanism
- Added window state management (position and size)
- Theme customization support

#### Bug Fixes
- Fixed issue with configuration file loading
- Resolved file selection inconsistencies
- Addressed potential crashes during startup

#### Improvements
- Optimized application performance
- Refactored code structure for better maintainability
- Updated dependencies to latest stable versions
- Enhanced logging for easier debugging

### Version 1.0

- Initial release
- Basic file selection functionality
- Simple panel interface
- Configuration file support

## Installation

1. Clone the repository
2. Open `myPanel.xcodeproj` in Xcode
3. Build and run the application (⌘R)

## Usage

Launch the application and use the panel buttons to select and open your frequently used files. Each item displays:
- A button to select or open the file/application
- The file/application icon
- The file name
- A clear button (X icon) to remove the item

The application remembers your last opened files and preferences automatically. Use the reset button in the top-right corner to clear all configuration.

## Configuration

The application stores its configuration in `myPanel.json`, including:
- Last opened files
- User preferences (theme, language)
- Window state (dimensions, position)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License