# Foundry Build Profiles

## Profiles
- `dev` - Fast iteration (via_ir=false, optimizer=false, sparse_mode=true)
- `deploy` - Production (via_ir=true, optimizer=true, build_info, storageLayout)
- `test` - Testing (sparse, reduced fuzz runs)
- `ci` - CI/CD (10k fuzz runs, verbosity=4)
- `gas` - Gas analysis (10k optimizer runs)
- `size` - Size optimization (1 optimizer run)

## Usage
```bash
FOUNDRY_PROFILE=dev forge build
FOUNDRY_PROFILE=deploy forge build
```

## Makefile Shortcuts
- `make build-dev` - Development
- `make build-prod` - Production (uses deploy profile)
- `make test-fast` - Quick tests
- `make build-gas` - Gas optimization

## Key Settings
- EVM version: cancun
- bytecode_hash: ipfs
- cbor_metadata: true
- Yul optimizer enabled
