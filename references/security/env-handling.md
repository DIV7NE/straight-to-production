# Environment Variable Handling

## Rules (non-negotiable)
- NEVER hardcode secrets, API keys, database URLs, or tokens in source code
- NEVER commit env files to git — add `.env*` to .gitignore immediately
- NEVER log environment variables or include them in error messages
- NEVER expose server-side secrets to client/browser code

## Pattern: Validate at Startup
Create an env validation module that validates all required variables when the application starts. This catches missing/malformed variables immediately instead of at runtime when a user triggers the code path.

Every stack has a validation library:
- **TypeScript**: Zod schema parsing process.env
- **Python**: Pydantic BaseSettings or python-dotenv + validation
- **Rust**: envy crate or dotenvy + manual validation
- **Go**: envconfig or viper with required tags
- **C#**: IOptions pattern with DataAnnotations
- **Java**: @ConfigurationProperties with @Validated
- **Ruby**: dotenv-rails + ENV.fetch (raises on missing)
- **PHP**: Laravel config with env() + validation

## Separation by Environment
- **Local development**: `.env.local` (gitignored, sensitive values)
- **Committed defaults**: `.env` or `.env.example` (non-sensitive, template for others)
- **Production**: Set via deployment platform (Vercel, Railway, AWS, Heroku, etc.)
- **Testing**: `.env.test` (test-specific overrides)

## Deployment Checklist
- Set all required env vars in deployment platform
- Use different values per environment (dev/staging/production)
- Rotate secrets regularly (API keys, database passwords)
- Use the platform's secret encryption for sensitive values
- Verify no secrets appear in build logs or error reports
