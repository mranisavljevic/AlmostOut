# CI/CD Setup for AlmostOut

This document explains the Continuous Integration setup for the AlmostOut iOS project.

## Overview

The CI system uses **GitHub Actions** and **Fastlane** to automatically run tests on every pull request, ensuring code quality and preventing broken code from being merged into the main branch.

## Components

### 1. Fastlane Configuration (`fastlane/`)

- **`Fastfile`**: Defines lanes for testing, building, and CI operations
- **`Appfile`**: App-specific configuration (currently minimal for testing-focused setup)

#### Available Fastlane Lanes:

- `fastlane test` - Run tests locally
- `fastlane ci_test` - Run tests optimized for CI (with detailed logging)
- `fastlane build_for_testing` - Build the app for testing
- `fastlane lint` - Run SwiftLint (if available)
- `fastlane ci` - Full CI pipeline (build + lint + test)

### 2. GitHub Actions Workflows (`.github/workflows/`)

#### `pr-tests.yml`
- **Trigger**: Runs on every pull request to `main`
- **Purpose**: Execute full test suite and report results
- **Features**:
  - Caching for faster builds (Swift Package Manager, DerivedData)
  - Parallel linting job
  - Test result artifacts upload
  - Automatic PR comments with test status
  - Commit status updates

#### `setup-branch-protection.yml`
- **Trigger**: Manual workflow dispatch
- **Purpose**: Configure branch protection rules for main branch
- **One-time setup**: Run once to enable required status checks

## Branch Protection Rules

When activated, the following rules apply to the `main` branch:

✅ **Required Status Checks**:
- `ci/tests` - All unit tests must pass
- `All Checks Complete` - Full CI pipeline must complete successfully

✅ **Pull Request Requirements**:
- At least 1 approving review required
- Stale reviews are dismissed when new commits are pushed

✅ **Protection Features**:
- No direct force pushes to main
- Branch cannot be deleted
- Admins can bypass rules in emergencies

## Setup Instructions

### Initial Setup

1. **Enable GitHub Actions** (if not already enabled):
   - Go to repository Settings → Actions → General
   - Ensure "Allow all actions and reusable workflows" is selected

2. **Set up branch protection** (one-time):
   - Go to repository Actions tab
   - Run "Setup Branch Protection" workflow manually
   - Select `main` as the branch to protect

3. **Verify setup**:
   - Create a test PR
   - Verify that tests run automatically
   - Check that merge is blocked until tests pass

### Local Development

Run tests locally using Fastlane:

```bash
cd AlmostOut
# Install fastlane (if needed)
gem install fastlane

# Run tests
fastlane test

# Run full CI pipeline locally
fastlane ci
```

## Workflow Details

### Test Execution
- Tests run on `macos-latest` with latest stable Xcode
- Uses iPhone 16 simulator for consistent results
- UI tests are skipped for faster CI (unit tests only)
- Code coverage is collected and stored as artifacts

### Caching Strategy
- Swift Package Manager dependencies cached
- Xcode DerivedData cached
- Cache keys based on file content hashes for accuracy

### Error Handling
- Tests must pass for PR to be mergeable
- Failed tests trigger PR comments with status
- Artifacts preserved for 30 days for debugging

## Troubleshooting

### Common Issues

**Tests fail with "Unable to find device"**:
- Check that the simulator name in Fastfile matches available simulators
- Update device name to match Xcode version being used

**SwiftLint errors**:
- SwiftLint is optional - CI continues even if linting fails
- Install locally with `brew install swiftlint`

**Permission errors in branch protection setup**:
- Ensure repository admin access
- Check that GITHUB_TOKEN has sufficient permissions

**Build failures due to dependencies**:
- Dependencies are resolved before testing
- Check Package.resolved for version conflicts

### Monitoring

- **GitHub Actions tab**: View workflow runs and logs
- **Pull Request checks**: See status directly on PR pages  
- **Artifacts**: Download test results and logs for detailed analysis

## Customization

### Adding New Tests
Tests are automatically discovered - just add test files following the pattern `*Tests.swift` in the test targets.

### Modifying Test Configuration
Edit the `run_tests` parameters in `fastlane/Fastfile`:
- Change simulator device
- Modify code coverage settings  
- Add/remove test targets

### Workflow Customization
Edit `.github/workflows/pr-tests.yml`:
- Adjust timeout values
- Modify caching strategy
- Change notification settings
- Add additional checks (security scanning, etc.)

---

## Benefits

✅ **Quality Assurance**: Automated testing catches issues before merge  
✅ **Consistent Environment**: Same test environment for all contributors  
✅ **Fast Feedback**: Results appear directly on PRs within minutes  
✅ **Artifact Preservation**: Test results and logs saved for analysis  
✅ **Branch Protection**: Prevents accidental merging of broken code  
✅ **Developer Friendly**: Clear status indicators and helpful error messages