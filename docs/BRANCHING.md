# Branching Strategy

Battle Castles uses a Git Flow-inspired branching strategy to keep the game stable and development organized.

## Branch Structure

### `main` (Protected)
- **Purpose**: Stable, playable builds only
- **Rules**:
  - No direct commits allowed
  - Only merge from `develop` via PR
  - Should always be in a working state
  - Represents production-ready code

### `develop`
- **Purpose**: Integration branch where features come together
- **Rules**:
  - Features merge here first
  - Test thoroughly before merging to `main`
  - May have minor bugs, but should be mostly playable

### `feature/*`
- **Purpose**: Individual feature development
- **Naming**: `feature/feature-name` (e.g., `feature/ai-phase-2`)
- **Rules**:
  - Branch from `develop`
  - Merge back to `develop` when complete
  - Delete after merging

### `bugfix/*`
- **Purpose**: Bug fixes
- **Naming**: `bugfix/bug-description` (e.g., `bugfix/archer-range`)
- **Rules**:
  - Branch from `develop` (or `main` for hotfixes)
  - Merge back to source branch
  - Delete after merging

## Workflow

### Starting a New Feature

```bash
# Make sure develop is up to date
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/my-feature

# Work on feature, commit often
git add .
git commit -m "feat: add new feature"

# Push feature branch
git push -u origin feature/my-feature
```

### Completing a Feature

```bash
# Make sure feature is up to date with develop
git checkout develop
git pull origin develop
git checkout feature/my-feature
git merge develop

# Test the feature thoroughly

# Create PR to develop
gh pr create --base develop --title "feat: My Feature" --body "Description of changes"

# After PR is approved and merged, delete feature branch
git checkout develop
git pull origin develop
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

### Releasing to Main

```bash
# Periodically (weekly or at milestones), merge develop to main

# Test develop thoroughly first!

# Create PR from develop to main
git checkout develop
git pull origin develop
gh pr create --base main --title "Release: Milestone X" --body "Tested features ready for main"

# After merge, tag the release
git checkout main
git pull origin main
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

### Hotfix for Main

```bash
# For critical bugs in main that can't wait for next release

# Branch from main
git checkout main
git pull origin main
git checkout -b bugfix/critical-issue

# Fix the bug
git add .
git commit -m "fix: critical issue"

# Create PR to main
gh pr create --base main --title "hotfix: Critical Issue" --body "Fix description"

# After merge, also merge to develop
git checkout develop
git merge main
git push origin develop
```

## Best Practices

1. **Commit Often**: Make small, focused commits with clear messages
2. **Test Before Merging**: Always test your branch before creating a PR
3. **Keep Branches Short-Lived**: Merge features within a few days
4. **Pull Before Push**: Always pull latest changes before pushing
5. **Delete Merged Branches**: Clean up branches after they're merged
6. **Use Descriptive Names**: `feature/ai-difficulty` not `feature/stuff`
7. **One Feature Per Branch**: Don't mix multiple features in one branch

## Commit Message Format

Use conventional commits format:

- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `docs:` Documentation changes
- `test:` Test additions/changes
- `chore:` Maintenance tasks

Example: `feat: Add AI difficulty selector to settings menu`

## Current Branches

- `main` - Latest stable release (protected)
- `develop` - Integration branch
- `feature/settings-page-fixes` - Current work on settings improvements

## Questions?

If you're unsure about the workflow, ask before making changes to main or develop directly!
