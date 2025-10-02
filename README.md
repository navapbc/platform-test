# platform-test

This repo is used to test the [Nava Platform](https://github.com/navapbc/platform).

Namely the [AWS infrastructure
template](https://github.com/navapbc/template-infra), with multiple applications
and environments:

| App Name                                                                                     | Dev URL                                           | Prod URL                           |
|----------------------------------------------------------------------------------------------|---------------------------------------------------|------------------------------------|
| app <br /> ([source](https://github.com/navapbc/template-infra/tree/main/template-only-app)) | https://platform-test-dev.navateam.com            | https://platform-test.navateam.com |
| app-flask <br /> ([source](http://app-flask-dev-1457072397.us-east-1.elb.amazonaws.com))           | http://app-flask-dev-1457072397.us-east-1.elb.amazonaws.com |                                    |
| app-nextjs <br /> ([source](http://app-nextjs-dev-63935901.us-east-1.elb.amazonaws.com))         | http://app-nextjs-dev-63935901.us-east-1.elb.amazonaws.com/ |                                    |
| app-rails <br /> ([source](https://github.com/navapbc/template-application-rails))           | https://app-rails.platform-test-dev.navateam.com/ |                                    |

## Applications

### app-flask

Flask application using [template-application-flask](https://github.com/navapbc/template-application-flask).

### app-nextjs

Next.js application using [template-application-nextjs](https://github.com/navapbc/template-application-nextjs).

**Resources:**
- Storybook: https://navapbc.github.io/platform-test/app-nextjs/storybook/

