#!/bin/zsh

# ci_post_clone.sh
# Xcode Cloud runs this script immediately after cloning the repository.
# You can use it to inspect the environment, install additional tools via Homebrew, or prepare build dependencies.

set -e

echo "=== Xcode Cloud Post-Clone Script ==="
echo "Build Number: ${CI_BUILD_NUMBER:-Local}"
echo "Branch: ${CI_BRANCH:-N/A}"
echo "Commit: ${CI_COMMIT:-N/A}"
echo "Workflow: ${CI_WORKFLOW:-N/A}"
echo "Xcode Version: $(xcodebuild -version)"
echo "Swift Version: $(swift --version | head -n 1)"
echo "=== Post-Clone Setup Complete ==="
