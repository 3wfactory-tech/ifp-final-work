# ProcessPayments - AI Coding Guidelines

## Project Overview
This is an Elixir library for payment processing functionality. Currently implements basic greeting functionality as a starting point.

## Architecture
- **Main Module**: `ProcessPayments` in `lib/process_payments.ex`
- **Structure**: Standard Mix project with `lib/` for source code, `test/` for ExUnit tests
- **Naming**: Module uses `ProcessPayments` (camel case), app name is `:proccess_payments` (snake case with typo)

## Development Workflow
- **Build**: `mix compile` - compiles Elixir code to BEAM bytecode
- **Test**: `mix test` - runs ExUnit tests including doctests
- **Format**: `mix format` - applies Elixir code formatting using `.formatter.exs` rules
- **Interactive**: `iex -S mix` - starts interactive Elixir shell with project loaded

## Code Patterns
- **Modules**: Define in `lib/` with `@moduledoc` and `@doc` for documentation
- **Tests**: Place in `test/` with `_test.exs` suffix, use `doctest` for documentation examples
- **Functions**: Follow Elixir conventions - descriptive names, pattern matching, immutable data
- **Example**: `ProcessPayments.hello()` returns `:world` atom

## Dependencies & Publishing
- **Current**: No external dependencies (commented out in `mix.exs`)
- **Publishing**: Ready for Hex.pm - update description in README, add version tags
- **Integration**: Add deps to `mix.exs` deps() function for external libraries

## Key Files
- `lib/process_payments.ex` - Main module implementation
- `test/process_payments_test.exs` - Unit tests with ExUnit
- `mix.exs` - Project configuration and dependencies
- `.formatter.exs` - Code formatting rules

## Adding Features
1. Add new functions to `ProcessPayments` module with proper documentation
2. Create corresponding tests in `test/process_payments_test.exs`
3. Run `mix test` to verify functionality
4. Use `mix format` to maintain code style

Focus on functional programming principles, pattern matching, and Elixir's immutable data structures for payment processing logic.