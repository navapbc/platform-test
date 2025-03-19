import { EmailAddress, EmailService } from '../../lib/services/email/EmailService';
import { expect, test } from '@playwright/test';
import { MessageCheckerService } from '../../lib/services/email/MessageCheckerService';

test.describe('Email notifications', () => {
  test('send test email notification', async ({ page, context }) => {
    const emailService: EmailService = new MessageCheckerService(context);
    const emailAddress: EmailAddress = emailService.generateEmailAddress(emailService.generateUsername());

    await page.goto('/email-notifications');
    await page.getByRole('textbox').fill(emailAddress);
    await page.getByRole('button').click();

    const email = await emailService.waitForEmailWithSubject(emailAddress, 'Test notification');
    expect(email.text).toContain('This is a system generated test notification');
  });
});
