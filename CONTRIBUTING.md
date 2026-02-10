# INDICATE GitHub Contribution Guide

## About INDICATE

INDICATE (INfrastructure for Data-driven Innovation in Critical carE) is a pan-European federated data infrastructure for ICU data that enables cross-border healthcare research while maintaining data sovereignty. The project connects 15+ ICU institutions across multiple European countries.

**Key Principles:**
- Patient data never leaves hospitals
- Federated architecture with distributed computation
- Open collaboration and community-driven development
- Full regulatory compliance (GDPR, EHDS, NIS2D, AI Act)

## What You Can Contribute

These repositories are for:

✅ **Collaborative Development**
- Minimal viable dataset specifications
- Extended dataset definitions
- Use case development and requirements
- Technical documentation and guides
- Shared libraries and utilities
- Common data models and schemas
- Testing frameworks and tools

❌ **Not Included Here**
- Infrastructure as Code for INDICATE central services (managed separately)
- Study packages and research code (follow separate governance process)
- Federated analysis or learning projects (use Study Repository)

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. ✅ Signed the appropriate agreement (Consortium or Accession Agreement) as an organization
2. ✅ Access to INDICATE GitHub repositories (via B2B invitation)
3. ✅ Completed INDICATE user onboarding
4. ✅ Set up your development environment

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/indicate/[repository-name].git
cd [repository-name]

# 2. Create a feature branch
git checkout -b feature/brief-description

# 3. Make your changes
# ... edit files ...

# 4. Run local checks (example for Python)
black src/
flake8 src/
pytest tests/

# 5. Commit and push
git add .
git commit -m "feat: brief description of changes"
git push origin feature/brief-description

# 6. Create a Pull Request on GitHub
```

## How to Contribute

### 1. Create a Branch

Use descriptive branch names:
- `feature/[description]` - New features
- `bugfix/[description]` - Bug fixes
- `docs/[description]` - Documentation updates

### 2. Make Your Changes

Follow these guidelines:
- Write clear, readable code
- Add comments for complex logic
- Include tests for new functionality
- Update documentation as needed

### 3. Commit Your Work

Use clear commit messages:
```
type(scope): brief description

- Detailed explanation if needed
- Link to requirements: REQ###
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 4. Create a Pull Request

When creating a PR:
1. Fill in the pull request template
2. Link to related requirements (REQ###)
3. Describe what you changed and why
4. Request review from appropriate team members

## Code Standards

### Python
```python
# Use type hints
def process_data(patient_id: str, values: list[float]) -> dict:
    """Process patient data according to OMOP CDM.
    
    Args:
        patient_id: Unique patient identifier
        values: List of measurement values
        
    Returns:
        Processed data dictionary
    """
    pass

# Format with Black
black src/

# Check with flake8
flake8 src/
```

### JavaScript/TypeScript
```javascript
// Use TypeScript for type safety
interface DatasetMetadata {
  datasetId: string;
  title: string;
  description: string;
}

// Format with Prettier
npm run format

// Lint with ESLint
npm run lint
```

### General Rules
- Use meaningful variable names
- Write tests for new code
- Document public APIs

## Security Requirements

### ❌ Never Commit

- Passwords or API keys
- Personal data
- Connection strings with credentials
- Private certificates

### ✅ Always Do

- Run security scans before committing
- Check dependencies for vulnerabilities
- Add license headers to new files

### Running Security Checks

```bash
# Python
bandit -r src/
safety check

# JavaScript
npm audit

# Check for secrets
git secrets --scan
```

## Licensing

All contributions must be licensed under:

**European Union Public License (EUPL) v1.2**

Add this header to new files:

```python
# Copyright (c) 2025 [Your Organization]
# Licensed under the EUPL-1.2
# See: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
```

## Review Process

### What Reviewers Check

✅ Functionality works correctly  
✅ Code follows standards  
✅ Tests pass  
✅ Documentation is updated  
✅ No security issues  
✅ Requirements are linked (if applicable) 

### Timeline

- Initial review: Within 10 business days
- Follow-up reviews: Within 5 business days
- Urgent changes: Tag as `urgent` for priority

## Getting Help

### Documentation

PLACEHOLDER

### Support

**General questions:**: info@indicate-europe.eu

### Community

PLACEHOLDER

## Common Questions

**Q: How do I link my code to requirements?**

Add comments in your code:
```python
# Implements: REQ015 - Central Metadata Catalog
# Related: AD014 - Knowledge Repository Approach
```

**Q: My tests pass locally but fail in CI. Why?**

Check for:
- Environment differences
- Missing dependencies in requirements.txt
- Timing issues in tests
- Different Python/Node versions

**Q: Can I use a third-party library?**

Yes, if:
- License is EUPL-compatible (e.g. Apache, MIT, BSD)
- No known security vulnerabilities
- Listed in requirements.txt or package.json

**Q: How do I request a new feature?**

1. Create a GitHub issue
2. Describe the feature and use case
3. Tag with `enhancement`
4. Discuss with the team

## Troubleshooting

### Build Failures

```bash
# Clear cache and reinstall
rm -rf node_modules/
npm install

# Or for Python
rm -rf venv/
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Permission Issues

Contact your repository administrator if:
- Can't push to your branch
- Can't create pull requests
- Missing from GitHub team

## Repository Structure

```
repository-name/
├── README.md              # Repository overview
├── CONTRIBUTING.md        # This file
├── LICENSE                # EUPL-1.2 license
├── docs/                  # Documentation
│   ├── architecture/      # Architecture decisions
│   └── guides/           # User guides
├── src/                   # Source code
├── tests/                 # Test files
├── config/                # Configuration files
└── .github/              # GitHub workflows
```

## Thank You!

Thank you for contributing to INDICATE! Your work helps advance European healthcare research while maintaining the highest standards of data protection and patient privacy.

---

**Questions?** Contact the INDICATE team at info@indicate-europe.eu

**License:** European Union Public License v1.2  
**Copyright:** © 2025 INDICATE Consortium

*This project has received funding from the European Union's Digital Europe Programme.*
