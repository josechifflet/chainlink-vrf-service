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
setup:; make build && \
	make install && \
	make format

# Install dependencies
install:; ./install.sh && make install_deps

# Update Dependencies
update:; forge update

# Build the project
build:; forge build

# Run tests
test:; forge test -vvv --gas-report

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