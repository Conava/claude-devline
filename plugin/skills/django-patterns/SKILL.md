---
name: django-patterns
description: "Django development conventions: project structure, ORM patterns, DRF serializers/viewsets, service layer, security (CSRF, XSS, SQL injection), testing with pytest-django + factory_boy, middleware, signals, and caching."
disable-model-invocation: false
user-invocable: false
---

# Django Patterns

Domain knowledge for Django development. Follow these conventions when implementing Django code.

## Project Structure

- Split settings: `config/settings/{base,development,production,test}.py`
- Apps under `apps/` directory, each with `models.py`, `views.py`, `serializers.py`, `services.py`, `urls.py`, `permissions.py`, `filters.py`, `tests/`
- Use `config/` for root `urls.py`, `wsgi.py`, `asgi.py`
- Always define a custom user model (`AbstractUser`) before first migration
- Set `AUTH_USER_MODEL = 'users.User'` in base settings

## Settings

- Base: shared config, `SECRET_KEY` from env, PostgreSQL default, middleware stack
- Development: `DEBUG=True`, `console` email backend, `debug_toolbar`
- Production: `DEBUG=False`, `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, HSTS headers, env-based `ALLOWED_HOSTS`
- Test: in-memory SQLite, disabled migrations, `MD5PasswordHasher` for speed, eager Celery

## Models

- Always set `class Meta`: `db_table`, `ordering`, `indexes`, `constraints`, `verbose_name`
- Use `__str__` on every model
- Use `DecimalField` for money (never `FloatField`)
- Use `PositiveIntegerField` for counts
- Add `created_at = DateTimeField(auto_now_add=True)` and `updated_at = DateTimeField(auto_now=True)`
- Use `validators` on fields, plus `CheckConstraint` for database-level enforcement
- Override `save()` sparingly; prefer signals or service layer for side effects

## Custom QuerySets and Managers

- Define `QuerySet` subclass with chainable filter methods: `.active()`, `.in_stock()`, `.with_category()`
- Attach via `objects = MyQuerySet.as_manager()`
- Use separate `Manager` for operations like `get_or_none()`, `create_with_relations()`, `bulk_update_field()`
- Chain custom querysets: `Product.objects.active().with_category().in_stock()`

## Query Optimization

- `select_related()` for ForeignKey / OneToOne (single JOIN)
- `prefetch_related()` for ManyToMany / reverse FK (separate query, Python join)
- Always set `queryset` on ViewSets with appropriate `select_related`/`prefetch_related`
- Use `only()` / `defer()` for large text/blob fields
- Use `bulk_create()`, `bulk_update()` for batch operations
- Add composite indexes for common filter + order combinations

## DRF Serializers

- Separate read and write serializers: `ProductSerializer` vs `ProductCreateSerializer`
- Use `source='relation.field'` with `read_only=True` for nested display fields
- Use `SerializerMethodField` for computed values
- Validate single fields with `validate_<field>(self, value)`
- Validate cross-field logic in `validate(self, data)`
- Use `write_only=True` for passwords; call `set_password()` in `create()`

## DRF ViewSets

- Inherit `ModelViewSet` for full CRUD, override `get_serializer_class()` per action
- Set `permission_classes`, `filter_backends`, `filterset_class`, `search_fields`, `ordering_fields`
- Use `perform_create()` to inject request context (e.g., `created_by=request.user`)
- Add custom endpoints with `@action(detail=True/False, methods=[...])`
- Always paginate list endpoints

## DRF Permissions

- `IsOwnerOrReadOnly`: check `obj.author == request.user` for write methods
- `IsAdminOrReadOnly`: `request.user.is_staff` for write, open for safe methods
- Combine with `IsAuthenticated` at the ViewSet level
- Use Django model-level `permissions` in `Meta` for fine-grained RBAC

## Service Layer

- Place business logic in `services.py`, not in views or serializers
- Wrap multi-step mutations in `@transaction.atomic`
- Services are plain classes or functions; views call them, tests mock them
- Keep services framework-agnostic where possible

## Security

### Production Hardening
- `DEBUG = False`, env-sourced `SECRET_KEY` (fail if missing)
- `SECURE_SSL_REDIRECT = True`, `SECURE_HSTS_SECONDS = 31536000`
- `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `CSRF_COOKIE_HTTPONLY`
- `X_FRAME_OPTIONS = 'DENY'`, `SECURE_CONTENT_TYPE_NOSNIFF = True`
- Use `Argon2PasswordHasher` as primary hasher

### CSRF
- Always include `{% csrf_token %}` in forms
- For AJAX: read `csrftoken` cookie and send as `X-CSRFToken` header
- Only `@csrf_exempt` for external webhooks with signature verification

### SQL Injection
- Never use f-strings or `.format()` in raw SQL; always use parameterized queries: `raw('... WHERE x = %s', [val])`
- Prefer ORM `filter()` and `Q()` objects for all queries

### XSS
- Django auto-escapes template variables; never use `|safe` on user input
- Use `format_html()` instead of `mark_safe()` for HTML with variables
- Use `|escapejs` in `<script>` blocks

### File Uploads
- Validate extension and size via model validators
- Serve uploads from a separate domain or S3; never from the app origin
- Never trust `Content-Type` headers from clients

### API Rate Limiting
- Configure DRF throttle classes: `AnonRateThrottle`, `UserRateThrottle`
- Set per-scope rates in `REST_FRAMEWORK['DEFAULT_THROTTLE_RATES']`

### CORS
- Use `django-cors-headers` middleware; whitelist specific origins
- Never set `CORS_ALLOW_ALL_ORIGINS = True` in production

## Testing with pytest-django

### Configuration
- `pytest.ini`: `DJANGO_SETTINGS_MODULE = config.settings.test`, `--reuse-db`, `--nomigrations`, `--cov=apps`
- Mark slow tests with `@pytest.mark.slow`, integration with `@pytest.mark.integration`

### conftest.py Fixtures
- `user(db)`: regular user via factory
- `admin_user(db)`: superuser via factory
- `authenticated_client(client, user)`: `client.force_login(user)`
- `api_client()`: `APIClient()`
- `authenticated_api_client(api_client, user)`: `api_client.force_authenticate(user=user)`

### factory_boy Factories
- `UserFactory`: `Sequence` for email/username, `PostGenerationMethodCall('set_password', ...)`
- `ProductFactory`: `SubFactory(CategoryFactory)`, `FuzzyDecimal` for price, `@post_generation` for M2M tags
- Use `create_batch(n)` for bulk test data

### What to Test
- **Models**: creation, `__str__`, validation, custom manager methods, constraints
- **Serializers**: serialization output, deserialization + validation, field-level and cross-field validators
- **Views/API**: status codes, permissions (authenticated vs anonymous), filtering, search, pagination
- **Services**: business logic, transaction atomicity, edge cases
- Use `@pytest.mark.parametrize` for input variants
- Mock at boundaries: payment gateways, email, external APIs via `@patch`
- Use `django.core.mail.outbox` for email assertions
- Use `override_settings()` for config-dependent tests

### Coverage Targets
- Models 90%+, Services 90%+, Serializers 85%+, Views 80%+, Overall 80%+

## Signals

- Register in `apps.py` `ready()` method via `import apps.<name>.signals`
- Keep signal handlers thin; delegate to service layer
- Use `post_save` with `created` flag for one-time setup (e.g., profile creation)

## Middleware

- Use `MiddlewareMixin` for class-based middleware
- Common patterns: request timing/logging, active user tracking, security headers
- Order matters: SecurityMiddleware first, then session, CORS, common, CSRF, auth

## Caching

- View-level: `@cache_page(timeout)` or `@method_decorator(cache_page(timeout), name='dispatch')`
- Low-level: `cache.get(key)` / `cache.set(key, value, timeout)` for expensive queries
- Invalidate on writes; use signal handlers or service layer to bust cache
- Template fragments: `{% cache timeout name %}...{% endcache %}`

## Anti-Patterns to Avoid

- Business logic in views or serializers instead of service layer
- Missing `select_related`/`prefetch_related` causing N+1 queries
- Using `FloatField` for monetary values
- Hardcoded secrets or `DEBUG=True` in production settings
- Raw SQL with string interpolation
- Using `|safe` on user-supplied content
- Fat models that mix persistence with business logic
- Skipping custom user model (cannot change after first migration)
- Testing Django internals or third-party library behavior
- Mutable default arguments on model methods
