#!/bin/bash
# Bump version across all project files
# Usage: ./scripts/bump-version.sh [patch|minor|major]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$PROJECT_DIR/VERSION"

# Read current version
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found"
    exit 1
fi

CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Determine bump type
BUMP_TYPE="${1:-patch}"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Usage: $0 [patch|minor|major]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version: $NEW_VERSION"

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update pyproject.toml
sed -i '' "s/^version = \".*\"/version = \"$NEW_VERSION\"/" "$PROJECT_DIR/pyproject.toml"

# Update setup.py
sed -i '' "s/version=\".*\",/version=\"$NEW_VERSION\",/" "$PROJECT_DIR/setup.py"

# Update SKILL.md (in frontmatter)
sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PROJECT_DIR/SKILL.md"

# Update CHANGELOG.md - add new version header if not exists
if ! grep -q "## \[$NEW_VERSION\]" "$PROJECT_DIR/CHANGELOG.md"; then
    DATE=$(date +%Y-%m-%d)
    # Create temp file with new version section
    {
        head -1 "$PROJECT_DIR/CHANGELOG.md"
        echo ""
        echo "## [$NEW_VERSION] - $DATE"
        echo ""
        echo "### Changed"
        echo "- Version bump"
        echo ""
        tail -n +2 "$PROJECT_DIR/CHANGELOG.md"
    } > "$PROJECT_DIR/CHANGELOG.md.tmp"
    mv "$PROJECT_DIR/CHANGELOG.md.tmp" "$PROJECT_DIR/CHANGELOG.md"
fi

echo ""
echo "Version bumped to $NEW_VERSION in:"
echo "  - VERSION"
echo "  - pyproject.toml"
echo "  - setup.py"
echo "  - SKILL.md"
echo "  - CHANGELOG.md"
