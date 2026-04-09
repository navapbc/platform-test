import { expect, test } from '@playwright/test';

test.describe('Catala API tests', () => {
  test('should return 200 from /health', async ({ request }) => {
    const response = await request.get('/health');
    expect(response.status()).toBe(200);
  });
});
