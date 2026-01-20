# AdPriva Contracts - Makefile
# Simplifies common development and deployment tasks

.PHONY: help install build test coverage gas-snapshot clean format lint \
	deploy-testnet deploy-mainnet verify smoke-test \
	test-anchor

# Default target
help:
	@echo "AdPriva Contracts - Available Commands"
	@echo ""
	@echo "Development:"
	@echo "  make install          - Install dependencies"
	@echo "  make build            - Build contracts"
	@echo "  make test             - Run all tests"
	@echo "  make test-anchor      - Run Anchor tests only"
	@echo "  make test-verbose     - Run tests with verbose output"
	@echo "  make coverage         - Generate coverage report"
	@echo "  make gas-snapshot     - Generate gas snapshot"
	@echo "  make format           - Format code"
	@echo "  make lint             - Run linter"
	@echo "  make clean            - Clean build artifacts"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-testnet   - Deploy to Horizen testnet"
	@echo "  make deploy-mainnet   - Deploy to Horizen mainnet (requires confirmation)"
	@echo "  make verify           - Verify deployment"
	@echo "  make smoke-test       - Run smoke tests on deployed contract"
	@echo ""

# Install dependencies
install:
	@echo "Installing Foundry dependencies..."
	forge install
	@echo "✓ Dependencies installed"

# Build contracts
build:
	@echo "Building contracts..."
	forge build
	@echo "✓ Build complete"

# Run all tests
test:
	@echo "Running all tests..."
	forge test
	@echo "✓ Tests complete"

# Run Anchor tests only
test-anchor:
	@echo "Running Anchor tests..."
	forge test --match-contract AnchorTest
	@echo "✓ Anchor tests complete"


# Run tests with verbose output
test-verbose:
	@echo "Running tests with verbose output..."
	forge test -vvv

# Generate coverage report
coverage:
	@echo "Generating coverage report..."
	forge coverage
	@echo "✓ Coverage report generated"

# Generate gas snapshot
gas-snapshot:
	@echo "Generating gas snapshot..."
	forge snapshot
	@echo "✓ Gas snapshot saved to .gas-snapshot"

# Format code
format:
	@echo "Formatting code..."
	forge fmt
	@echo "✓ Code formatted"

# Run linter
lint:
	@echo "Running linter..."
	forge fmt --check
	@echo "✓ Lint check complete"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	forge clean
	rm -rf out cache
	@echo "✓ Clean complete"

# Deploy to Horizen testnet
deploy-testnet:
	@echo "Deploying Anchor to Horizen testnet..."
	@if [ -z "$$PRIVATE_KEY" ]; then \
		echo "Error: PRIVATE_KEY not set. Create .env file with your private key."; \
		exit 1; \
	fi
	forge script script/DeployHorizenTestnet.s.sol:DeployHorizenTestnet \
		--rpc-url horizen_testnet \
		--broadcast \
		-vvvv
	@echo "✓ Deployment complete"

# Deploy to Horizen mainnet (with confirmation)
deploy-mainnet:
	@echo "⚠️  WARNING: You are about to deploy to MAINNET"
	@echo "This will use real funds and cannot be undone."
	@read -p "Are you sure? Type 'DEPLOY MAINNET' to confirm: " confirm; \
	if [ "$$confirm" = "DEPLOY MAINNET" ]; then \
		echo "Deploying to mainnet..."; \
		forge script script/DeployBase.s.sol:DeployBase \
			--rpc-url horizen_mainnet \
			--broadcast \
			--verify \
			-vvvv; \
		echo "✓ Mainnet deployment complete"; \
	else \
		echo "Deployment cancelled."; \
	fi

# Verify deployment
verify:
	@echo "Verifying deployment..."
	forge script script/VerifyDeployment.s.sol:VerifyDeployment \
		--rpc-url horizen_testnet \
		-vvv
	@echo "✓ Verification complete"

# Run smoke tests
smoke-test:
	@echo "Running smoke tests..."
	forge test --match-contract SmokeTests -vv
	@echo "✓ Smoke tests complete"


# Run forge fmt on all files
fmt:
	@echo "Formatting Solidity files..."
	forge fmt
	@echo "✓ Formatting complete"

# Check if environment is set up correctly
check-env:
	@echo "Checking environment setup..."
	@if [ ! -f .env ]; then \
		echo "⚠️  .env file not found. Copy .env.example to .env"; \
		exit 1; \
	fi
	@if [ -z "$$PRIVATE_KEY" ]; then \
		echo "⚠️  PRIVATE_KEY not set in .env"; \
		exit 1; \
	fi
	@echo "✓ Environment configured"

# Display gas report
gas-report:
	@echo "Generating gas report..."
	forge test --gas-report
	@echo "✓ Gas report complete"

# Run slither static analysis (if installed)
slither:
	@echo "Running Slither static analysis..."
	@if command -v slither >/dev/null 2>&1; then \
		slither . --config-file slither.config.json 2>/dev/null || \
		slither . --exclude-dependencies; \
	else \
		echo "Error: slither not found. Install from https://github.com/crytic/slither"; \
		exit 1; \
	fi

# Quick check before committing
pre-commit: format lint test
	@echo "✓ Pre-commit checks passed"

# Run all checks (format, lint, build, test)
check: format lint build test
	@echo "✓ All checks passed"
