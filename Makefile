# ClawBack - OpenClaw Skill Makefile
# Usage: make help

.PHONY: help install setup test clean bump-patch bump-minor bump-major release publish

# Default registry (use www to avoid redirect issues)
CLAWHUB_REGISTRY ?= https://www.clawhub.ai
VERSION := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
SKILL_SLUG := clawback

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo ""
	@echo "$(CYAN)ClawBack - OpenClaw Skill$(NC)"
	@echo "$(CYAN)=========================$(NC)"
	@echo "Current version: $(GREEN)$(VERSION)$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Release workflow:$(NC)"
	@echo "  1. make bump-patch    # or bump-minor, bump-major"
	@echo "  2. make release       # commit, tag, and push"
	@echo "  3. make publish       # publish to ClawHub"
	@echo ""

# ============================================================================
# Installation
# ============================================================================

install: ## Install the package in development mode
	@echo "$(CYAN)Installing ClawBack...$(NC)"
	python3 -m pip install -e .
	@echo "$(GREEN)Done!$(NC)"

setup: ## Run the setup wizard
	@echo "$(CYAN)Running setup wizard...$(NC)"
	./setup.sh

venv: ## Create virtual environment
	@echo "$(CYAN)Creating virtual environment...$(NC)"
	python3 -m venv venv
	@echo "$(GREEN)Activate with: source venv/bin/activate$(NC)"

deps: venv ## Install dependencies in venv
	@echo "$(CYAN)Installing dependencies...$(NC)"
	. venv/bin/activate && pip install --upgrade pip && pip install -e .
	@echo "$(GREEN)Done!$(NC)"

# ============================================================================
# Development
# ============================================================================

test: ## Run tests (if any)
	@echo "$(CYAN)Running tests...$(NC)"
	python3 -m pytest tests/ -v 2>/dev/null || echo "$(YELLOW)No tests found$(NC)"

lint: ## Run linter
	@echo "$(CYAN)Running linter...$(NC)"
	python3 -m flake8 src/clawback/ --max-line-length=120 2>/dev/null || echo "$(YELLOW)flake8 not installed$(NC)"

clean: ## Clean build artifacts
	@echo "$(CYAN)Cleaning...$(NC)"
	rm -rf build/ dist/ *.egg-info src/*.egg-info
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true
	@echo "$(GREEN)Clean!$(NC)"

# ============================================================================
# Version Management
# ============================================================================

version: ## Show current version
	@echo "$(VERSION)"

bump-patch: ## Bump patch version (0.0.X)
	@echo "$(CYAN)Bumping patch version...$(NC)"
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh patch
	@echo "$(GREEN)Version bumped to $$(cat VERSION)$(NC)"

bump-minor: ## Bump minor version (0.X.0)
	@echo "$(CYAN)Bumping minor version...$(NC)"
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh minor
	@echo "$(GREEN)Version bumped to $$(cat VERSION)$(NC)"

bump-major: ## Bump major version (X.0.0)
	@echo "$(CYAN)Bumping major version...$(NC)"
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh major
	@echo "$(GREEN)Version bumped to $$(cat VERSION)$(NC)"

# ============================================================================
# Release & Publishing
# ============================================================================

release: ## Commit version bump, create tag, and push
	@echo "$(CYAN)Creating release v$(VERSION)...$(NC)"
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "$(YELLOW)No changes to commit$(NC)"; \
	else \
		git add VERSION pyproject.toml setup.py SKILL.md CHANGELOG.md; \
		git commit -m "chore(release): bump version to $(VERSION)"; \
		echo "$(GREEN)Committed version $(VERSION)$(NC)"; \
	fi
	@if git tag | grep -q "^v$(VERSION)$$"; then \
		echo "$(YELLOW)Tag v$(VERSION) already exists$(NC)"; \
	else \
		git tag -a "v$(VERSION)" -m "Release v$(VERSION)"; \
		echo "$(GREEN)Created tag v$(VERSION)$(NC)"; \
	fi
	@git push origin main --tags
	@echo "$(GREEN)Pushed to origin$(NC)"

publish: ## Publish to ClawHub
	@echo "$(CYAN)Publishing to ClawHub...$(NC)"
	@echo "Version: $(VERSION)"
	@echo "Registry: $(CLAWHUB_REGISTRY)"
	@echo ""
	clawhub publish . \
		--slug $(SKILL_SLUG) \
		--version $(VERSION) \
		--tags latest \
		--registry $(CLAWHUB_REGISTRY)
	@echo ""
	@echo "$(GREEN)Published $(SKILL_SLUG)@$(VERSION) to ClawHub!$(NC)"

publish-dry: ## Dry run of publish (show what would happen)
	@echo "$(CYAN)Publish dry run...$(NC)"
	@echo ""
	@echo "Would run:"
	@echo "  clawhub publish . \\"
	@echo "    --slug $(SKILL_SLUG) \\"
	@echo "    --version $(VERSION) \\"
	@echo "    --tags latest \\"
	@echo "    --registry $(CLAWHUB_REGISTRY)"
	@echo ""
	@echo "Files to be published:"
	@find . -type f -not -path './.git/*' -not -path './venv/*' | sort

# ============================================================================
# Combined Commands
# ============================================================================

release-patch: bump-patch release ## Bump patch, commit, tag, push
	@echo "$(GREEN)Released patch version$(NC)"

release-minor: bump-minor release ## Bump minor, commit, tag, push
	@echo "$(GREEN)Released minor version$(NC)"

release-major: bump-major release ## Bump major, commit, tag, push
	@echo "$(GREEN)Released major version$(NC)"

ship-patch: release-patch publish ## Bump patch and publish to ClawHub
	@echo "$(GREEN)Shipped patch release!$(NC)"

ship-minor: release-minor publish ## Bump minor and publish to ClawHub
	@echo "$(GREEN)Shipped minor release!$(NC)"

ship-major: release-major publish ## Bump major and publish to ClawHub
	@echo "$(GREEN)Shipped major release!$(NC)"
