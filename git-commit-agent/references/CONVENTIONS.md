# Commit Message Conventions

完整的 commit message 规范参考文档。

## Table of Contents

1. [Vue.js Commit Convention](#vuejs-convention)
2. [Conventional Commits](#conventional-commits)
3. [Type Definitions](#type-definitions)
4. [Scope Patterns](#scope-patterns)
5. [Validation Rules](#validation-rules)

---

## VueJS Convention

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Example

```
feat(auth): add JWT token authentication

- Implement JWT generation and validation
- Add login/logout endpoints
- Store tokens in httpOnly cookies

Closes #123
```

### Structure

**Header** (required):
- `type`: Commit type (feat, fix, docs, etc.)
- `scope`: Affected component/module
- `subject`: Brief description

**Body** (optional for simple commits):
- Motivation for the change
- Contrast with previous behavior

**Footer** (optional):
- Breaking changes
- Referencing issues
- Commit metadata

---

## Conventional Commits

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Example

```
feat(api): add user endpoint

Add new endpoint for user management.
Supports CRUD operations.

BREAKING CHANGE: API now uses JSON instead of XML
```

### Key Differences from Vue.js

- Scope is optional (not in parentheses)
- Simpler format, less structured
- Focuses on automated tooling compatibility

---

## Type Definitions

### Standard Types

| Type | Description | When to Use |
|------|-------------|-------------|
| `feat` | New feature | Adding user-facing functionality |
| `fix` | Bug fix | Fixing a bug |
| `docs` | Documentation | Only documentation changes |
| `style` | Code style | Format, missing semi colons, etc. No code logic change |
| `refactor` | Code refactoring | Neither fixes bug nor adds feature |
| `perf` | Performance | Improving performance |
| `test` | Tests | Adding or updating tests |
| `chore` | Chores | Build process, auxiliary tools, dependencies |
| `ci` | CI | CI configuration files and scripts |
| `build` | Build | Build system or external dependencies |
| `revert` | Revert | Revert a previous commit |

### Type Selection Decision Tree

```
Is it adding a new feature?
├─ Yes → feat
└─ No
   ├─ Is it fixing a bug?
   │  ├─ Yes → fix
   │  └─ No
   │     ├─ Is it documentation only?
   │     │  ├─ Yes → docs
   │     │  └─ No
   │        ├─ Is it test-related?
   │        │  ├─ Yes → test
   │        │  └─ No
   │           ├─ Is it performance related?
   │           │  ├─ Yes → perf
   │           │  └─ No
   │              ├─ Is it refactoring?
   │              │  ├─ Yes → refactor
   │              │  └─ No
   │                 ├─ Is it CI/build related?
   │                 │  ├─ Yes → ci or build
   │                 │  └─ No
   │                    └─ chore (default)
   └─ Is it reverting a commit?
      └─ Yes → revert
```

### User Context Keywords

When user provides context, map keywords to types:

**Chinese Keywords**:
- "新功能", "添加", "实现" → feat
- "修复", "bug", "问题" → fix
- "文档", "说明" → docs
- "测试" → test
- "重构", "优化" → refactor (if no new features)
- "性能" → perf
- "配置" → chore

**English Keywords**:
- "add", "implement", "new" → feat
- "fix", "bug", "issue" → fix
- "doc", "readme" → docs
- "test", "spec" → test
- "refactor", "clean up" → refactor
- "optimize", "performance" → perf
- "config", "setup" → chore

---

## Scope Patterns

### Common Scopes

#### Backend Scopes
- `backend` - General backend changes
- `api` - API layer
- `auth` - Authentication/authorization
- `db` - Database related
- `service` - Business logic services
- `controller` - API controllers
- `model` - Data models

#### Frontend Scopes
- `frontend` - General frontend changes
- `ui` - UI components
- `components` - React/Vue components
- `styles` - CSS/styling
- `state` - State management (Redux, Vuex, etc.)

#### Infrastructure Scopes
- `ci` - CI/CD configuration
- `deploy` - Deployment scripts
- `config` - Configuration files
- `deps` - Dependencies

#### Documentation Scopes
- `docs` - Documentation
- `readme` - README file
- `api-docs` - API documentation

### Scope Inference

From file paths:
```
backend/service/UserService.java  → scope: backend or service
frontend/src/components/Header.tsx → scope: frontend or components
docs/api.md                        → scope: docs
.github/workflows/ci.yml          → scope: ci
pom.xml                           → scope: deps or build
```

### Scope Selection Logic

```
If single module:
    use module name as scope

If multiple related modules (same domain):
    use domain scope (e.g., "auth" for auth-service + auth-frontend)

If multiple unrelated modules (single commit):
    omit scope or use "*"

If multiple unrelated modules (split commits):
    each commit uses its own scope
```

---

## Validation Rules

### Vue.js Convention Rules

#### Header Format

```
<type>(<scope>): <subject>
```

**Rules**:
1. Type is required (must be from allowed types)
2. Scope is optional (in parentheses)
3. Colon and space after scope/type
4. Subject is required

#### Subject Rules

1. **Imperative mood**: Use "add" not "added" or "adding"
   - ✅ "add user authentication"
   - ❌ "added user authentication"
   - ❌ "adding user authentication"

2. **Lowercase first letter**:
   - ✅ "fix authentication bug"
   - ❌ "Fix authentication bug"

3. **No period at end**:
   - ✅ "implement login feature"
   - ❌ "implement login feature."

4. **Max 50 characters**:
   - ✅ "add user authentication" (25 chars)
   - ❌ "add comprehensive user authentication system with role-based access control" (78 chars)

#### Body Rules

1. **What and Why, not How**:
   - ✅ "Add JWT authentication for improved security"
   - ❌ "Add JWT using passport-jwt library"

2. **Max 72 characters per line**:
   - ✅ Wrap long lines

3. **Use bullet points for lists**:
   ```
   - Add JWT generation
   - Implement token validation
   - Store tokens in cookies
   ```

#### Footer Rules

1. **Breaking Changes**:
   ```
   BREAKING CHANGE: API now uses camelCase
   ```

2. **Referencing Issues**:
   ```
   Closes #123
   Fixes #456
  Refs #789
   ```

### Conventional Commits Rules

Similar to Vue.js but:
- Scope is optional (not in parentheses)
- Format: `<type>[(scope)]: <description>`

### Quality Scoring

#### Score Components (0-100)

**1. Format Correctness (20 points)**
- Matches `<type>(<scope>): <subject>`: 20 pts
- Minor issues: 10-15 pts
- Doesn't match: 0 pts

**2. Clarity (25 points)**
- Subject ≤ 50 chars: 10 pts
- No period at end: 10 pts
- Lowercase first letter: 5 pts

**3. Completeness (20 points)**
- Has body (for complex commits): 20 pts
- No body (for simple commits): 15 pts
- Should have body but doesn't: 5 pts

**4. Scope Accuracy (20 points)**
- Scope is accurate: 20 pts
- No scope but acceptable: 10 pts
- Wrong or missing scope: 0 pts

**5. Historical Consistency (15 points)**
- Matches project style: 15 pts
- Deviates from style: 5-10 pts

#### Score Interpretation

- **90-100**: Excellent ⭐⭐⭐⭐⭐
- **80-89**: Good ⭐⭐⭐⭐
- **70-79**: Acceptable ⭐⭐⭐
- **< 70**: Needs improvement ⭐⭐

---

## Examples by Type

### feat (New Feature)

```
feat(auth): add JWT token authentication

- Implement JWT generation and validation
- Add login/logout endpoints
- Store tokens in httpOnly cookies

Closes #123
```

### fix (Bug Fix)

```
fix(api): resolve user profile update error

Correct null pointer exception when updating
user profile without avatar image.
```

### docs (Documentation)

```
docs: update API documentation with new endpoints

Add examples for user management endpoints.
Document authentication requirements.
```

### style (Code Style)

```
style: format code with black

Apply consistent formatting to Python files.
No functional changes.
```

### refactor (Refactoring)

```
refactor(service): extract user validation logic

Move validation logic from UserService to
UserValidator class for reusability.
```

### perf (Performance)

```
perf(api): optimize database query for user list

Add index on user.email column.
Reduce query time from 500ms to 50ms.
```

### test (Tests)

```
test(auth): add unit tests for JWT validation

Cover token generation, validation, and
expiration scenarios.
```

### chore (Chores)

```
chore: upgrade dependencies to latest versions

Update pytest, requests, and flask packages.
```

### ci (CI Configuration)

```
ci: add automated testing workflow

Configure GitHub Actions to run tests on
push and pull requests.
```

### build (Build System)

```
build: migrate from webpack to vite

Update build configuration for faster builds
and hot module replacement.
```

### revert (Revert)

```
revert: feat(auth): add JWT authentication

This reverts commit abc1234 due to
security concerns with token storage.
```

---

## Breaking Changes

### Format

```
<type>(<scope>): <subject>

BREAKING CHANGE: <description>
```

### Example

```
feat(api): change response format to camelCase

BREAKING CHANGE: API responses now use camelCase
instead of snake_case. This affects all endpoints.

Migration guide: docs/migration-guide.md
```

---

## Multi-Line Commit Bodies

### Complex Feature

```
feat(auth): implement OAuth2 authentication

- Add OAuth2 providers (Google, GitHub)
- Implement token exchange flow
- Store OAuth tokens securely
- Update user profile with OAuth data

Closes #456
Refs #789
```

### Major Refactoring

```
refactor: redesign data access layer

- Extract repository pattern from services
- Introduce ORM for database operations
- Separate business logic from data access
- Add transaction management

BREAKING CHANGE: Service layer interface changed.
Update controllers to use new repository methods.
```

---

## Language-Specific Patterns

### Python

```
feat(api): add user registration endpoint

Implement POST /users/register endpoint with
email validation and password hashing.

Closes #123
```

### JavaScript/TypeScript

```
feat(components): add DatePicker component

Create reusable date picker with:
- Date range selection
- Custom date formats
- Localization support

Closes #456
```

### Java

```
feat(service): implement UserService

Add business logic for user CRUD operations.
Integrate with UserRepository and validate
input data.

Closes #789
```

---

## Quick Reference Card

### Commit Message Template

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Subject Checklist

- [ ] Imperative mood ("add" not "added")
- [ ] Lowercase first letter
- [ ] No period at end
- [ ] ≤ 50 characters
- [ ] Clear and concise

### Body Checklist

- [ ] Explain what and why
- [ ] Use bullet points for lists
- [ ] Wrap at 72 characters
- [ ] Include relevant details

### Common Patterns

```
feat(module): add feature

fix(module): fix bug

docs: update documentation

refactor(module): improve code structure

test(module): add tests

chore: update dependencies
```
