# ClawBack - OpenClaw Skill Makefile
# Usage: make help

.PHONY: help install setup test clean bump-patch bump-minor bump-major release publish

# Default registry (use www to avoid redirect issues)
CLAWHUB_REGISTRY ?= https://www.clawhub.ai
SKILL_SLUG := clawback

# Read version dynamically (not cached)
version = $(shell cat VERSION.txt 2>/dev/null || echo "0.0.0")

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
	@echo "Current version: $(GREEN)$(version)$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Release workflow (one command):$(NC)"
	@echo "  make ship-patch    # bump, commit, tag, push, publish"
	@echo "  make ship-minor"
	@echo "  make ship-major"
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
	@echo "$(version)"

bump-patch: ## Bump patch version (0.0.X)
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh patch

bump-minor: ## Bump minor version (0.X.0)
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh minor

bump-major: ## Bump major version (X.0.0)
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh major

# ============================================================================
# Release & Publishing
# ============================================================================

release: ## Commit version bump, create tag, and push
	@echo "$(CYAN)Creating release v$(version)...$(NC)"
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "$(YELLOW)No changes to commit$(NC)"; \
	else \
		git add -A; \
		git commit -m "chore(release): bump version to $(version)"; \
		echo "$(GREEN)Committed version $(version)$(NC)"; \
	fi
	@if git tag | grep -q "^v$(version)$$"; then \
		echo "$(YELLOW)Tag v$(version) already exists, deleting...$(NC)"; \
		git tag -d "v$(version)"; \
		git push origin --delete "v$(version)" 2>/dev/null || true; \
	fi
	@git tag -a "v$(version)" -m "Release v$(version)"
	@echo "$(GREEN)Created tag v$(version)$(NC)"
	@git push origin main --tags
	@echo "$(GREEN)Pushed to origin$(NC)"

publish: ## Publish to ClawHub
	@echo "$(CYAN)Publishing to ClawHub...$(NC)"
	@echo "Version: $(version)"
	@echo "Registry: $(CLAWHUB_REGISTRY)"
	@echo ""
	@# Copy to OpenClaw workspace (ClawHub looks there)
	@rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)
	@mkdir -p ~/.openclaw/workspace/skills
	@cp -r . ~/.openclaw/workspace/skills/$(SKILL_SLUG)
	@rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.git
	@rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.idea
	@rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.claude
	@echo "Copied to ~/.openclaw/workspace/skills/$(SKILL_SLUG)"
	clawhub publish ~/.openclaw/workspace/skills/$(SKILL_SLUG) \
		--slug $(SKILL_SLUG) \
		--version $(version) \
		--changelog "Release v$(version)" \
		--tags latest \
		--registry $(CLAWHUB_REGISTRY)
	@echo ""
	@echo "$(GREEN)Published $(SKILL_SLUG)@$(version) to ClawHub!$(NC)"

publish-dry: ## Dry run of publish (show what would happen)
	@echo "$(CYAN)Publish dry run...$(NC)"
	@echo ""
	@echo "Would run:"
	@echo "  clawhub publish . \\"
	@echo "    --slug $(SKILL_SLUG) \\"
	@echo "    --version $(version) \\"
	@echo "    --tags latest \\"
	@echo "    --registry $(CLAWHUB_REGISTRY)"
	@echo ""
	@echo "Files to be published:"
	@find . -type f -not -path './.git/*' -not -path './venv/*' | sort

# ============================================================================
# Combined Commands (Ship = bump + release + publish)
# ============================================================================

ship-patch: ## Bump patch, commit, tag, push, publish - ALL IN ONE
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)  Shipping patch release$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh patch
	@echo ""
	@NEW_VER=$$(cat VERSION.txt); \
	echo "$(CYAN)Committing v$$NEW_VER...$(NC)"; \
	git add -A; \
	git commit -m "chore(release): bump version to $$NEW_VER"; \
	echo "$(CYAN)Tagging v$$NEW_VER...$(NC)"; \
	git tag -d "v$$NEW_VER" 2>/dev/null || true; \
	git push origin --delete "v$$NEW_VER" 2>/dev/null || true; \
	git tag -a "v$$NEW_VER" -m "Release v$$NEW_VER"; \
	echo "$(CYAN)Pushing to origin...$(NC)"; \
	git push origin main --tags; \
	echo ""; \
	echo "$(CYAN)Publishing to ClawHub...$(NC)"; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG); \
	mkdir -p ~/.openclaw/workspace/skills; \
	cp -r . ~/.openclaw/workspace/skills/$(SKILL_SLUG); \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.git; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.idea; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.claude; \
	clawhub publish ~/.openclaw/workspace/skills/$(SKILL_SLUG) \
		--slug $(SKILL_SLUG) \
		--version $$NEW_VER \
		--changelog "Release v$$NEW_VER" \
		--tags latest \
		--registry $(CLAWHUB_REGISTRY); \
	echo ""; \
	echo "$(GREEN)========================================$(NC)"; \
	echo "$(GREEN)  Shipped $(SKILL_SLUG)@$$NEW_VER$(NC)"; \
	echo "$(GREEN)========================================$(NC)"

ship-minor: ## Bump minor, commit, tag, push, publish - ALL IN ONE
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)  Shipping minor release$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh minor
	@echo ""
	@NEW_VER=$$(cat VERSION.txt); \
	echo "$(CYAN)Committing v$$NEW_VER...$(NC)"; \
	git add -A; \
	git commit -m "chore(release): bump version to $$NEW_VER"; \
	echo "$(CYAN)Tagging v$$NEW_VER...$(NC)"; \
	git tag -d "v$$NEW_VER" 2>/dev/null || true; \
	git push origin --delete "v$$NEW_VER" 2>/dev/null || true; \
	git tag -a "v$$NEW_VER" -m "Release v$$NEW_VER"; \
	echo "$(CYAN)Pushing to origin...$(NC)"; \
	git push origin main --tags; \
	echo ""; \
	echo "$(CYAN)Publishing to ClawHub...$(NC)"; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG); \
	mkdir -p ~/.openclaw/workspace/skills; \
	cp -r . ~/.openclaw/workspace/skills/$(SKILL_SLUG); \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.git; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.idea; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.claude; \
	clawhub publish ~/.openclaw/workspace/skills/$(SKILL_SLUG) \
		--slug $(SKILL_SLUG) \
		--version $$NEW_VER \
		--changelog "Release v$$NEW_VER" \
		--tags latest \
		--registry $(CLAWHUB_REGISTRY); \
	echo ""; \
	echo "$(GREEN)========================================$(NC)"; \
	echo "$(GREEN)  Shipped $(SKILL_SLUG)@$$NEW_VER$(NC)"; \
	echo "$(GREEN)========================================$(NC)"

ship-major: ## Bump major, commit, tag, push, publish - ALL IN ONE
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)  Shipping major release$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@chmod +x scripts/bump-version.sh
	@./scripts/bump-version.sh major
	@echo ""
	@NEW_VER=$$(cat VERSION.txt); \
	echo "$(CYAN)Committing v$$NEW_VER...$(NC)"; \
	git add -A; \
	git commit -m "chore(release): bump version to $$NEW_VER"; \
	echo "$(CYAN)Tagging v$$NEW_VER...$(NC)"; \
	git tag -d "v$$NEW_VER" 2>/dev/null || true; \
	git push origin --delete "v$$NEW_VER" 2>/dev/null || true; \
	git tag -a "v$$NEW_VER" -m "Release v$$NEW_VER"; \
	echo "$(CYAN)Pushing to origin...$(NC)"; \
	git push origin main --tags; \
	echo ""; \
	echo "$(CYAN)Publishing to ClawHub...$(NC)"; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG); \
	mkdir -p ~/.openclaw/workspace/skills; \
	cp -r . ~/.openclaw/workspace/skills/$(SKILL_SLUG); \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.git; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.idea; \
	rm -rf ~/.openclaw/workspace/skills/$(SKILL_SLUG)/.claude; \
	clawhub publish ~/.openclaw/workspace/skills/$(SKILL_SLUG) \
		--slug $(SKILL_SLUG) \
		--version $$NEW_VER \
		--changelog "Release v$$NEW_VER" \
		--tags latest \
		--registry $(CLAWHUB_REGISTRY); \
	echo ""; \
	echo "$(GREEN)========================================$(NC)"; \
	echo "$(GREEN)  Shipped $(SKILL_SLUG)@$$NEW_VER$(NC)"; \
	echo "$(GREEN)========================================$(NC)"
