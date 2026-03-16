# Documentation Tools

## Static Site Generators

### MkDocs (Python)
- Config: `mkdocs.yml`
- Content: `docs/` directory with `.md` files
- Build: `mkdocs build`, serve: `mkdocs serve`
- Material theme recommended for modern look
- Supports admonitions, tabs, code highlighting

### Docusaurus (JavaScript)
- Config: `docusaurus.config.js`
- Content: `docs/` with `.md` or `.mdx` files
- Features: versioning, i18n, search, blog
- React-based with MDX support

### VitePress (JavaScript)
- Config: `.vitepress/config.js`
- Lightweight Vue-powered static site
- Markdown with Vue components
- Fast HMR development

## API Documentation

### OpenAPI / Swagger
- Spec: `openapi.yaml` or `openapi.json`
- Tools: Swagger UI, Redoc, Stoplight
- Generate client SDKs from spec
- Validate requests/responses against spec

### TypeDoc (TypeScript)
- Config: `typedoc.json`
- Generates HTML from TSDoc comments
- Supports plugins and themes

### Javadoc (Java)
- Built into JDK
- Generates HTML from `/** */` comments
- Standard tags: `@param`, `@return`, `@throws`

### Godoc (Go)
- Built into Go toolchain
- Generates from regular comments above declarations
- Convention: first sentence is summary

### Rustdoc (Rust)
- Built into Cargo: `cargo doc`
- Markdown in `///` doc comments
- Runs doc tests automatically

## Inline Documentation

### JSDoc (JavaScript/TypeScript)
```javascript
/**
 * Creates a new user account.
 * @param {string} name - The user's display name
 * @param {string} email - The user's email address
 * @returns {Promise<User>} The created user object
 * @throws {ValidationError} If email is invalid
 */
```

### Python Docstrings
```python
def create_user(name: str, email: str) -> User:
    """Create a new user account.

    Args:
        name: The user's display name.
        email: The user's email address.

    Returns:
        The created user object.

    Raises:
        ValidationError: If email is invalid.
    """
```

### KDoc (Kotlin)
```kotlin
/**
 * Creates a new user account.
 * @param name The user's display name
 * @param email The user's email address
 * @return The created user object
 * @throws ValidationException if email is invalid
 */
```
