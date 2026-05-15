import { expect, test } from '@playwright/test';

// TODO(https://github.com/navapbc/strata-template-documentai-api/issues/43) A more robust E2E test suite
test.describe('DocumentAI API tests', () => {
  test('should return 200 from /health', async ({ request }) => {
    const response = await request.get('/health');
    expect(response.status()).toBe(200);
  });
});
