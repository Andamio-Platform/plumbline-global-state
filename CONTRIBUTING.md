# Contributing to plumbline-global-state

Thank you for your interest in contributing to the Andamio Protocol.

## Prerequisites

- [Aiken v1.1.19](https://aiken-lang.org/installation-instructions)

## Getting Started

```sh
aiken build
aiken check
```

Tests live in `validators/tests/`, `lib/plumbline/tests.ak`, and `validators/example/tests.ak`. To run a subset:

```sh
aiken check -m <test_name>
```

## How to Contribute

### Reporting Bugs

Open a [GitHub Issue](https://github.com/Andamio-Platform/plumbline-global-state/issues) with:
- A clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior

### Suggesting Changes

Open an issue before writing code for non-trivial changes. This avoids wasted effort if the direction doesn't align with the project roadmap.

### Submitting a Pull Request

1. Fork the repository and create a branch from `main`
2. Make your changes with clear, focused commits
3. Ensure `aiken check` passes with no failures
4. Open a PR against `main` with a description of what changed and why

## Security

Please do **not** open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md) for responsible disclosure instructions.

## License

By contributing, you agree that your contributions will be licensed under the [Apache 2.0 License](LICENSE).
