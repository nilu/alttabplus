# DirectionalAltTab

A macOS application that enhances the Alt-Tab experience by allowing directional mouse clicks for window switching, inspired by the League of Legends ping system.

## Features

- Hold Alt key to activate
- Click and drag in any direction to select windows
- Quick and intuitive window switching
- Native macOS integration

## Requirements

- macOS 10.15 or later
- Xcode 13.0 or later

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run the application

## Usage

1. Hold the Alt (Option) key
2. Click and drag in any direction to select a window
3. Release to switch to the selected window

## Development

This project is built using Swift and AppKit, utilizing macOS accessibility features for window management.

## TODO
1. Create Xcode project structure ⏳
2. Implement window selection logic in WindowManager.switchToWindow(at:)
3. Add visual overlay to show available windows
4. Add window preview thumbnails
5. Fine-tune mouse tracking sensitivity
6. Add unit tests
7. Add keyboard shortcut customization
8. Add window filtering options
9. Implement window preview caching for better performance

## Development Setup

### 1. Prerequisites
- Install Xcode (required for SDK and developer tools)
- Install Cursor from https://cursor.sh/
- Install Homebrew (optional but recommended)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Project Setup
1. Clone the repository
```bash
git clone https://github.com/yourusername/DirectionalAltTab.git
cd DirectionalAltTab
```

2. Open the project in Cursor
3. Install Swift dependencies (if any) using Swift Package Manager

### 3. Using Cursor AI Features

#### Code Generation
- Use `Cmd + K` to open AI chat
- Use `Cmd + L` for inline code suggestions
- Example prompts:
  ```
  "Create a window manager class using AppKit"
  "Help me implement mouse tracking for directional selection"
  "Generate Swift code for a radial menu UI"
  ```

#### AI-Assisted Development
- Use `/fix` command for code fixes
- Use `/explain` to understand complex code
- Use `/test` to generate unit tests
- Use `/docs` to generate documentation

### 4. Building and Running
1. Open Terminal in Cursor (Cmd + J)
2. Build the project:
```bash
xcodebuild -scheme DirectionalAltTab build
```
3. Run the application:
```bash
open build/Release/DirectionalAltTab.app
```

### 5. Development Tips
- Use Cursor's AI to help with AppKit APIs
- Leverage code completion for Swift syntax
- Use the integrated terminal for git commands
- Enable real-time error checking
- Use split views to see implementation and tests side by side

## Contributing

1. Fork the repository
2. Create your feature branch
3. Use Cursor's AI to help with:
   - Code review suggestions
   - Documentation generation
   - Test coverage
4. Submit a pull request
