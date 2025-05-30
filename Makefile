-include .env

VENV_DIR = venv
REQUIREMENTS_FILE = requirements.txt

# Target to create a virtual environment
create_venv:
	@echo "Creating virtual environment..."
	python3 -m venv $(VENV_DIR)

# Target to install dependencies
install_deps: create_venv $(REQUIREMENTS_FILE)
	@echo "Activating virtual environment and installing dependencies..."
	$(VENV_DIR)/bin/python -m pip install --upgrade pip
	$(VENV_DIR)/bin/pip install -r $(REQUIREMENTS_FILE)

# Target to clean up the virtual environment and requirements file
clean-venv:
	@echo "Cleaning up venv"
	rm -rf $(VENV_DIR)

# Clean the repo
clean:; forge clean && \
	rm -rf docs && \
	rm -rf coverage && \
	rm -rf cache out && \
	rm -rf artifacts && \
	rm -rf broadcast && \
	rm -rf node_modules && \
		rm -rf $(VENV_DIR)

# Remove modules
remove:; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Set up dependencies and build the project
setup:; make build-dev && \
	make install && \
	make format

# Production setup (full optimization)
setup-prod:; make build-prod && \
	make install && \
	make format

# Install dependencies
install:; ./install.sh && make install_deps

# Update Dependencies
update:; forge update

# Foundry management
foundry-update:; foundryup
foundry-version:; forge --version
foundry-check:; @echo "Checking Foundry version and profile support..." && forge --version && echo "Testing profile support..." && (FOUNDRY_PROFILE=dev forge build --help > /dev/null 2>&1 && echo "✅ Profiles supported" || echo "❌ Profiles not supported - please run 'make foundry-update'")

# Build the project
build:; forge build

# Build with different profiles
build-dev:; FOUNDRY_PROFILE=dev forge build
build-prod:; FOUNDRY_PROFILE=production forge build
build-test:; FOUNDRY_PROFILE=test forge build
build-gas:; FOUNDRY_PROFILE=gas forge build
build-size:; FOUNDRY_PROFILE=size forge build
build-ci:; FOUNDRY_PROFILE=ci forge build

# Performance optimized builds
build-fast:; FOUNDRY_PROFILE=dev forge build --sparse-mode
build-watch:; FOUNDRY_PROFILE=dev forge build --watch
build-skip-tests:; FOUNDRY_PROFILE=dev forge build --skip test --skip script
build-contracts-only:; FOUNDRY_PROFILE=dev forge build --contracts src/

# Force builds (clear cache)
build-clean:; forge clean && FOUNDRY_PROFILE=dev forge build
build-clean-prod:; forge clean && FOUNDRY_PROFILE=production forge build

# Build specific contracts (usage: make build-contract CONTRACT=src/VRFHandler.sol)
build-contract:; FOUNDRY_PROFILE=dev forge build --contracts $(CONTRACT)

# Build performance benchmarking
benchmark-build: clean
	@echo "Benchmarking forge build performance..."
	@echo "Building with dev profile (fast)..."
	@time FOUNDRY_PROFILE=dev forge build
	@forge clean
	@echo "Building with production profile (optimized)..."
	@time FOUNDRY_PROFILE=production forge build
	@forge clean
	@echo "Building with sparse mode..."
	@time FOUNDRY_PROFILE=dev forge build --sparse-mode
	@forge clean
	@echo "Building contracts only (skip test/script)..."
	@time FOUNDRY_PROFILE=dev forge build --skip test --skip script

# Cache management
cache-status:; forge cache ls
cache-clean:; forge cache clean
cache-info:; forge cache ls --verbose

# Run tests
test:; forge test -vvv --gas-report

# Test with different profiles
test-fast:; FOUNDRY_PROFILE=test forge test -vv
test-dev:; FOUNDRY_PROFILE=dev forge test -vvv --gas-report
test-gas:; FOUNDRY_PROFILE=gas forge test -vv --gas-report
test-verbose:; FOUNDRY_PROFILE=test forge test -vvvv

# Performance optimized testing
test-watch:; FOUNDRY_PROFILE=test forge test --watch -vv
test-specific:; FOUNDRY_PROFILE=test forge test --match-contract $(CONTRACT) -vv
test-function:; FOUNDRY_PROFILE=test forge test --match-test $(FUNCTION) -vv

# Create a snapshot
snapshot:; forge snapshot

# Format the code
format:; forge fmt

# Run Anvil
anvil:; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Run Slither
slither:; $(VENV_DIR)/bin/slither . --config-file slither.config.json --checklist

# Scope command
scope:; tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'

# Create scope file
scopefile:; @tree ./src/ | sed 's/└/#/g' | awk -F '── ' '!/\.sol$$/ { path[int((length($$0) - length($$2))/2)] = $$2; next } { p = "src"; for(i=2; i<=int((length($$0) - length($$2))/2); i++) if (path[i] != "") p = p "/" path[i]; print p "/" $$2; }' > scope.txt

# Linting commands
lint:; pnpm lint:sol
lint-sol:; forge fmt --check && pnpm solhint {script,src,test}/**/*.sol
	
# Test coverage
test-coverage:; forge coverage
test-coverage-report:; forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

# Docs
build-docs:; forge doc
docs:; forge doc --serve --port 4000

# Deploy Anvil
deploy-anvil:; forge script Deploy -vvv --rpc-url "http://127.0.0.1:8545"

# Help command - displays available build profiles and performance optimizations
help:
	@echo "=== Chainlink VRF Service - Build Optimization ==="
	@echo ""
	@echo "⚠️  FOUNDRY VERSION:"
	@echo "  make foundry-check    - Check Foundry version and profile support"
	@echo "  make foundry-update   - Update to latest Foundry version"
	@echo "  make foundry-version  - Show current Foundry version"
	@echo ""
	@echo "🚀 FAST DEVELOPMENT BUILDS (30-60 seconds):"
	@echo "  make build-dev        - Development build (via_ir=false, optimizer=false)"
	@echo "  make build-fast       - Fastest build with sparse mode"
	@echo "  make build-watch      - Watch mode for continuous development"
	@echo "  make setup            - Quick project setup with dev build"
	@echo ""
	@echo "⚡ PERFORMANCE OPTIMIZED BUILDS:"
	@echo "  make build-test       - Optimized for testing (sparse mode, reduced fuzz runs)"
	@echo "  make build-skip-tests - Build only src/ contracts (skip test/script)"
	@echo "  make build-contracts-only - Build only source contracts"
	@echo ""
	@echo "🎯 SPECIALIZED BUILDS:"
	@echo "  make build-prod       - Production build (via_ir=true, full optimization)"
	@echo "  make build-gas        - Gas optimization focus (10k optimizer runs)"
	@echo "  make build-size       - Size optimization focus (1 optimizer run)"
	@echo "  make build-ci         - CI/CD optimized build"
	@echo "  make setup-prod       - Full production setup"
	@echo ""
	@echo "🧪 TESTING COMMANDS:"
	@echo "  make test-fast        - Fast tests with test profile"
	@echo "  make test-watch       - Watch mode testing"
	@echo "  make test-gas         - Gas-optimized testing"
	@echo ""
	@echo "🔧 UTILITIES:"
	@echo "  make benchmark-build  - Compare build times across profiles"
	@echo "  make cache-clean      - Clean build cache"
	@echo "  make build-clean      - Clean build with dev profile"
	@echo ""
	@echo "📝 EXAMPLES:"
	@echo "  make build-contract CONTRACT=src/VRFHandler.sol"
	@echo "  make test-specific CONTRACT=VRFHandlerTest"
	@echo "  make test-function FUNCTION=testVRFRequest"
	@echo ""
	@echo "💡 TIP: If you get '--profile not found' errors, run 'make foundry-update'"
	@echo ""