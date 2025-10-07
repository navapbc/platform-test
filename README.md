# platform-test

This repo is used to test the [Nava Platform](https://github.com/navapbc/platform).

Namely the [AWS infrastructure
template](https://github.com/navapbc/template-infra), with multiple applications
and environments:

| App Name                                                                                     | Dev URL                                           | Prod URL                           |
|----------------------------------------------------------------------------------------------|---------------------------------------------------|------------------------------------|
| app <br /> ([source](https://github.com/navapbc/template-infra/tree/main/template-only-app)) | https://platform-test-dev.navateam.com            | https://platform-test.navateam.com |
| app-flask <br /> ([source](https://github.com/navapbc/template-application-flask))           | https://app-flask.platform-test-dev.navateam.com |                                    |
| app-nextjs <br /> ([source](https://github.com/navapbc/template-application-nextjs))         | https://app-nextjs.platform-test-dev.navateam.com |                                    |
| app-rails <br /> ([source](https://github.com/navapbc/template-application-rails))           | https://app-rails.platform-test-dev.navateam.com/ |                                    |

## Applications

### app-flask

**API Documentation:**
- Dev: https://app-flask.platform-test-dev.navateam.com/docs

**Authentication:**
To retrieve the API key for the dev environment:
```bash
aws ssm get-parameter --name "/app-flask-dev/api-auth-token" --with-decryption --query Parameter.Value --output text
```

### app-nextjs

Next.js application using [template-application-nextjs](https://github.com/navapbc/template-application-nextjs).

**Resources:**
- Storybook: https://navapbc.github.io/platform-test/app-nextjs/storybook/

