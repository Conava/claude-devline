---
name: springboot-patterns
description: "Spring Boot conventions and patterns. Auto-loaded when working with Spring Boot applications (@SpringBootApplication, @RestController)."
disable-model-invocation: false
user-invocable: false
---

# Spring Boot Patterns

Domain knowledge for Spring Boot development. Follow these conventions.

## Layered Architecture

Strict layering: Controller -> Service -> Repository

- **Controller**: HTTP handling only — parse request, call service, build response. No business logic.
- **Service**: Business logic, transaction management, orchestration. Services call repositories, never controllers.
- **Repository**: Data access only. Spring Data JPA interfaces or custom queries.
- Never skip layers (controller calling repository directly)

## Controller Conventions

- `@RestController` with `@RequestMapping("/api/v1/resources")`
- One controller per aggregate root
- Use `@Valid` on request body parameters for validation
- Return `ResponseEntity<T>` for explicit status codes
- Use `@PathVariable` for resource IDs, `@RequestParam` for filters
- Keep methods thin — delegate to services immediately

```java
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {
    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<OrderResponse> create(@Valid @RequestBody CreateOrderRequest request) {
        Order order = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(OrderResponse.from(order));
    }
}
```

## Service Conventions

- `@Service` annotation, constructor injection via `@RequiredArgsConstructor`
- `@Transactional` on class level for read-heavy services, method level for specific write operations
- `@Transactional(readOnly = true)` for read-only operations
- Throw domain exceptions, let global handler translate to HTTP responses

## Configuration

- Use `application.yml` (or `.properties`) with profiles
- Externalize all environment-specific config
- Use `@ConfigurationProperties` with prefix for typed config classes
- Never hardcode connection strings, secrets, or URLs
- Use `@Value` sparingly — prefer `@ConfigurationProperties`

## Error Handling

- Global `@ControllerAdvice` with `@ExceptionHandler` methods
- Map domain exceptions to HTTP status codes centrally
- Structured error response with code, message, details
- Never expose stack traces in production responses
- Use `@ResponseStatus` on custom exceptions for simple cases

## Validation

- Bean Validation annotations: `@NotNull`, `@NotBlank`, `@Size`, `@Email`, `@Pattern`
- Custom validators with `@Constraint` for complex rules
- Validate at controller entry with `@Valid`
- Service-level validation for business rules that depend on state

## Security

### JWT Authentication

Use `OncePerRequestFilter` for stateless token validation:

```java
@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    private final JwtService jwtService;

    public JwtAuthFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            Authentication auth = jwtService.authenticate(token);
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        chain.doFilter(request, response);
    }
}
```

### Method-Level Authorization

Enable with `@EnableMethodSecurity`. Use `@PreAuthorize` for expression-based access control, `@Secured` for role-based.

```java
@PreAuthorize("hasRole('ADMIN')")
@GetMapping("/users")
public List<UserDto> listUsers() { ... }

@PreAuthorize("@authz.isOwner(#id, authentication)")
@DeleteMapping("/users/{id}")
public ResponseEntity<Void> deleteUser(@PathVariable Long id) { ... }
```

Deny by default; expose only required scopes.

### Rate Limiting (Bucket4j)

Apply per-endpoint or per-client limits. Return 429 with retry hints.

```java
@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    private Bucket createBucket() {
        return Bucket.builder()
            .addLimit(Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1))))
            .build();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {
        String clientIp = request.getRemoteAddr();
        Bucket bucket = buckets.computeIfAbsent(clientIp, k -> createBucket());
        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.getWriter().write("{\"error\": \"Rate limit exceeded\"}");
        }
    }
}
```

### CORS Configuration

Configure at the security filter level, not per-controller. Never use `*` for allowed origins in production.

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("https://app.example.com"));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
    config.setAllowCredentials(true);
    config.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}

// In SecurityFilterChain:
http.cors(cors -> cors.configurationSource(corsConfigurationSource()));
```

### Password Encoding

Always hash passwords with BCrypt or Argon2 -- never store plaintext. Use `PasswordEncoder` bean.

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12); // cost factor 12
}
```

### Security Headers

Configure CSP, HSTS, X-Frame-Options, and referrer policy in the security filter chain:

```java
http.headers(headers -> headers
    .contentSecurityPolicy(csp -> csp
        .policyDirectives("default-src 'self'"))
    .frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin)
    .xssProtection(Customizer.withDefaults())
    .referrerPolicy(rp -> rp.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER)));
```

### Input Validation Beyond Bean Validation

- Sanitize HTML input with a whitelist before rendering
- Use parameterized queries (`:param` bindings) -- never concatenate strings in SQL
- Validate file uploads: size, content type, and extension

```java
// Validated DTO with constraints
public record CreateUserDto(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email String email,
    @NotNull @Min(0) @Max(150) Integer age
) {}
```

## Testing

### TDD Workflow

Follow the RED-GREEN-REFACTOR cycle:

1. **RED**: Write a failing test for desired behavior
2. **GREEN**: Write minimal code to make it pass
3. **REFACTOR**: Improve code while keeping tests green

### Controller Tests (@WebMvcTest + MockMvc)

Slice test that loads only the web layer. Use `@MockBean` to replace service dependencies.

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {
    @Autowired MockMvc mockMvc;
    @MockBean OrderService orderService;

    @Test
    void createOrder_validInput_returns201() throws Exception {
        when(orderService.create(any())).thenReturn(new OrderDto(1L, "Test"));

        mockMvc.perform(post("/api/v1/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "Test", "amount": 100}
                """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Test"));
    }

    @Test
    void createOrder_invalidInput_returns400() throws Exception {
        mockMvc.perform(post("/api/v1/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "", "amount": -1}
                """))
            .andExpect(status().isBadRequest());
    }
}
```

### Repository Tests (@DataJpaTest)

Slice test for JPA repositories. Use `@AutoConfigureTestDatabase` with Testcontainers for real DB.

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig.class)
class OrderRepositoryTest {
    @Autowired OrderRepository repo;

    @Test
    void savesAndFinds() {
        OrderEntity entity = new OrderEntity();
        entity.setName("Test");
        repo.save(entity);

        Optional<OrderEntity> found = repo.findByName("Test");
        assertThat(found).isPresent();
    }
}
```

### Integration Tests with Testcontainers

Use reusable containers for Postgres/Redis to mirror production. Wire via `@DynamicPropertySource`.

```java
@SpringBootTest
@Testcontainers
class OrderIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired OrderRepository orderRepository;

    @Test
    void fullWorkflow() {
        orderRepository.save(new OrderEntity("Test"));
        assertThat(orderRepository.findByName("Test")).isPresent();
    }
}
```

### JaCoCo Coverage Configuration

Target 80%+ coverage. Configure in Maven:

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.14</version>
    <executions>
        <execution>
            <goals><goal>prepare-agent</goal></goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>verify</phase>
            <goals><goal>report</goal></goals>
        </execution>
    </executions>
</plugin>
```

Run: `mvn -T 4 test && mvn jacoco:report` or `./gradlew test jacocoTestReport`

### Assertions and Utilities

- Prefer AssertJ (`assertThat`) for fluent, readable assertions
- Use `jsonPath` for JSON response verification
- Use `assertThatThrownBy(...)` for exception assertions
- Use `@MockBean` to replace beans in the Spring test context
- Use `@ParameterizedTest` with `@CsvSource` or `@MethodSource` for test variants
- Use test data builders for complex domain objects
