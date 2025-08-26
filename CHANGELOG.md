# 📋 Changelog - Cursor Setup Ubuntu

## [2.0.0] - 2025-08-26
### 🚀 Major Changes
- **Completely Automated Installation**: Removed manual Stable/Nightly mode selection
- **Automatic Version Detection**: Script now fetches latest version from cursor-ai-downloads repository
- **Unified Installation Mode**: Single, streamlined installation process
- **Enhanced Error Handling**: Robust handling of file busy errors and process management

### 🔧 Technical Improvements
- **Simplified Architecture**: Reduced code complexity (481 → 441 lines)
- **Intelligent Process Detection**: Uses `lsof` to detect file usage before replacement
- **Automatic Backup System**: Creates timestamped backups before file replacement
- **Improved Logging**: Better user feedback and error messages
- **Optimized Functions**: Streamlined code with centralized constants

### 🐛 Bug Fixes
- **File Busy Error**: Fixed "file is busy" errors during updates
- **Version Pattern Matching**: Corrected pattern matching for Cursor-X.X.X format
- **AppArmor Profile**: Fixed profile pattern to match actual AppImage names
- **Function Dependencies**: Resolved issues with undefined variables

### 📖 Documentation
- **Updated README**: Reflected new unified installation process
- **Removed Legacy References**: Eliminated Stable/Nightly mode documentation
- **Added Intelligent Update Handling**: Documented new process management features
- **Added Download Source Documentation**: Detailed explanation of cursor-ai-downloads repository
- **Added Security & Verification Section**: Information about download security and verification

### 🔄 Breaking Changes
- **Removed Mode Selection**: No longer prompts for Stable/Nightly choice
- **Automatic Downloads**: No manual download step required
- **Unified Menu**: Simplified menu structure

---

## [1.0.0] - Initial Release
### 🎯 Original Features
- **Stable/Nightly Mode Support**: Manual selection between versions
- **Manual AppImage Download**: Required user intervention
- **Basic Installation**: Standard Ubuntu setup with desktop integration
- **AppArmor Profile**: Basic security profile
- **Desktop Shortcuts**: Icon and menu integration

---

## 📝 Change Types
- 🚀 **Major Changes**: Significant feature additions or architectural changes
- 🔧 **Technical Improvements**: Code optimizations and performance enhancements
- 🐛 **Bug Fixes**: Resolved issues and error corrections
- 📖 **Documentation**: Updates to README, comments, or user guides
- 🔄 **Breaking Changes**: Modifications that may affect existing usage

---

## 🤝 Contributing
When adding new features or fixes, please:
1. Update this CHANGELOG.md file
2. Follow the existing format
3. Add your changes under the appropriate category
4. Test thoroughly before committing

---

*This changelog documents all significant changes to the cursor-setup-ubuntu project.*
