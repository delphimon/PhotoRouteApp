# Xcode Cloud Setup & Configuration Guide for PhotoRoute

This guide covers the project configuration, prerequisites, and steps to enable **Xcode Cloud** for continuous integration and delivery (CI/CD) for `PhotoRoute`.

---

## 1. Project Configuration Summary

The following settings have been verified and configured in the project:

| Setting | Value | Notes |
| :--- | :--- | :--- |
| **Shared Scheme** | `PhotoRoute` | Saved at `PhotoRoute.xcodeproj/xcshareddata/xcschemes/PhotoRoute.xcscheme` |
| **Bundle Identifier** | `org.adventureleader.photorouteapp` | Defined in target build settings |
| **Development Team** | `WF244Y4N2C` | Code Sign Style set to `Automatic` |
| **Target iOS Version** | `iOS 18.0+` | Uses Swift 6 / modern Swift concurrency |
| **Test Targets** | `PhotoRouteTests` | Configured in scheme test action (`GPXParserTests`, `RouteInterpolatorTests`) |
| **Custom CI Scripts** | `ci_scripts/ci_post_clone.sh` | Made executable (`chmod +x`), runs post-checkout in Xcode Cloud |
| **Source Control** | GitHub (`delphimon/PhotoRouteApp`) | Cleaned up user state (`xcuserdata/` untracked from Git) |

---

## 2. Prerequisites

Before creating workflows in Xcode:

1. **Apple Developer Program**: Ensure your Apple Developer Account is active and belongs to Team `WF244Y4N2C`.
2. **App Store Connect App Record**:
   - Ensure an App Record exists in [App Store Connect](https://appstoreconnect.apple.com) matching Bundle ID `org.adventureleader.photorouteapp`.
   - If not yet created, Xcode will prompt to create one during workflow setup.
3. **Repository Access**:
   - The Apple Xcode Cloud GitHub App must be authorized on `delphimon/PhotoRouteApp` (Xcode guides you through this authorization on first setup).

---

## 3. Creating Your First Workflow in Xcode

Because Xcode Cloud workflows are securely hosted in Apple Developer Services, initialize the workflow through the Xcode IDE:

1. In Xcode, navigate to the menu bar and select:
   **Product** > **Xcode Cloud** > **Create Workflow...**
   *(Or press ⌘9 to open the Report Navigator, click the **Cloud** tab, and click **Get Started...**)*
2. **Select Product**:
   - Choose **PhotoRoute** as the product.
3. **Review Default Workflow**:
   Xcode provides a default CI workflow:
   - **Environment**: macOS / Latest Xcode (Xcode 16 / 26+)
   - **Start Condition**: Branch Changes (e.g. pushes to `main`)
   - **Actions**:
     - **Test**: Run `PhotoRouteTests` on iOS Simulator
     - **Archive**: Build archive for iOS App
   - **Post-Actions**: Email notification on build success/failure.
4. **Connect Source Control**:
   - Click **Grant Access** to link Xcode Cloud with GitHub.
   - Authorize the Xcode Cloud GitHub App for repository `delphimon/PhotoRouteApp`.
5. **Save and Run**:
   - Click **Save**.
   - Select **Start Build** to kick off the initial build on Apple's infrastructure.

---

## 4. Recommended Workflow Strategies

### Workflow A: Continuous Integration (PR & Branch Validation)
- **Name**: `PhotoRoute CI`
- **Start Condition**: Pull Request Changes (`main`) & Branch Changes (`main`)
- **Actions**:
  - **Analyze**: Static analysis for compiler warnings.
  - **Test**: Run unit tests on iPhone 16 / iOS 18 Simulator.
- **Post-Action**: Update GitHub PR status checks.

### Workflow B: TestFlight Internal Distribution
- **Name**: `PhotoRoute TestFlight Release`
- **Start Condition**: Git Tag (e.g., `v*`) or manual trigger.
- **Actions**:
  - **Test**: Run unit tests.
  - **Archive**: iOS platform.
- **Post-Action**: Distribute to TestFlight Internal Testing group.

---

## 5. Custom CI Scripts (`ci_scripts`)

Xcode Cloud automatically detects executable scripts inside the `ci_scripts/` directory:

- [ci_scripts/ci_post_clone.sh](file:///Users/andrew/development/PhotoRouteApp/ci_scripts/ci_post_clone.sh):
  Runs immediately after repository cloning. Used for environment logging, installing dependencies via Homebrew, or configuring environment variables.
- *(Optional)* `ci_pre_xcodebuild.sh`:
  Runs before `xcodebuild` execution.
- *(Optional)* `ci_post_xcodebuild.sh`:
  Runs after `xcodebuild` (even if it fails), useful for custom artifact upload or analytics.

All custom scripts must have a shebang (e.g. `#!/bin/zsh`) and executable permissions (`chmod +x`).
