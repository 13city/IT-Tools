# Contributing to Enterprise IT Administration Scripts

We love your input! We want to make contributing to Enterprise IT Administration Scripts as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github
We use Github to host code, to track issues and feature requests, as well as accept pull requests.

## We Use [Github Flow](https://guides.github.com/introduction/flow/index.html)
Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code follows our coding standards.
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License
In short, when you submit code changes, your submissions are understood to be under the same [MIT License](LICENSE) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using Github's [issue tracker](https://github.com/13city/IT_Scripts/issues)
We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/13city/IT_Scripts/issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can.
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Coding Standards

### General
- Use consistent indentation (preferably spaces)
- Use meaningful variable and function names
- Include comments for complex logic
- Keep functions focused and modular
- Write self-documenting code where possible

### PowerShell
- Follow [PowerShell Best Practices and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Use approved verbs for function names
- Include comment-based help for functions
- Use proper error handling with try/catch blocks
- Follow naming conventions (PascalCase for functions, camelCase for variables)

### Python
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use virtual environments
- Include requirements.txt or setup.py
- Write docstrings for functions and classes
- Use type hints where appropriate

### Shell Scripts
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Make scripts executable
- Include shebang line
- Use shellcheck for validation
- Include usage information in comments

## Documentation Requirements

1. **README Files**
   - Each script should have its own README
   - Include purpose, usage, and examples
   - List dependencies and prerequisites
   - Provide configuration instructions

2. **Code Comments**
   - Document complex algorithms
   - Explain non-obvious technical decisions
   - Include references to relevant documentation

3. **Function Documentation**
   - Document parameters and return values
   - Include usage examples
   - Note any side effects

## Testing Guidelines

1. **Unit Tests**
   - Write tests for new functionality
   - Maintain existing tests
   - Ensure tests are meaningful

2. **Integration Tests**
   - Test interaction between components
   - Verify system-level functionality
   - Include environment setup instructions

3. **Test Documentation**
   - Document test coverage
   - Explain test scenarios
   - Include test data explanation

## License
By contributing, you agree that your contributions will be licensed under its MIT License.

## References
This document was adapted from the open-source contribution guidelines for [Facebook's Draft](https://github.com/facebook/draft-js/blob/master/CONTRIBUTING.md).
