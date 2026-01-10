# Code Conventions

## Solidity Style
- Pragma: `0.8.29` (fixed version)
- License: MIT
- Named imports only
- Section headers with box-drawing characters

## Contract Structure Order
1. Types (structs, enums)
2. State variables
3. Errors
4. Events
5. Constructor
6. External functions
7. Internal functions
8. Admin functions

## Naming
- Interfaces: `I` prefix (IVRFHandler)
- Internal vars: no underscore prefix
- Function params: `_` prefix
- Mappings: descriptive `key => value` syntax

## Error Handling
- Custom errors (no revert strings)
- Input validation at function start
- Check-Effects-Interactions pattern

## Testing
- Base test contract per feature
- Helper functions prefixed with `_`
- Mock contracts in `test/mocks/`
- Behavior tests in `test/behaviours/`
