import baseConfig from '../playwright.config';
import { deepMerge } from '../lib/util';
import { defineConfig } from '@playwright/test';

export default defineConfig(deepMerge(
  baseConfig,
  {
    use: {
      baseURL: baseConfig.use.baseURL || "localhost:3100",
      ignoreHTTPSErrors: true, // Ignore SSL certificate errors
      // emailServiceType: "Mailinator", // Options: ["MessageChecker", "Mailinator"]. Default: "MessageChecker"
    },
  }
));
