import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import greek from '../public/i18n/el-GR.json';

test('real frontend proxy reaches Spring Boot and PostgreSQL', async ({ page }, testInfo) => {
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  const health = page.waitForResponse(response => response.url().endsWith('/api/v1/health'));
  await page.goto('/');
  const response = await health;
  expect(response.status()).toBe(200);
  expect(await response.json()).toEqual({ status: 'UP', service: 'pitchpulse', database: 'UP' });
  await expect(page.getByRole('status')).toContainText(greek.connectivity.ready.title);
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath('foundation.png'), fullPage: true });
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: greek.navigation.skip })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.getByRole('main')).toBeFocused();
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
  expect(errors).toEqual([]);
});

test('loading and retry remain usable when the backend is unavailable', async ({ page }) => {
  let calls = 0;
  let releaseFirst: () => void = () => {};
  const gate = new Promise<void>(resolve => { releaseFirst = resolve; });
  await page.route('**/api/v1/health', async route => {
    calls++;
    if (calls === 1) {
      await gate;
      await route.fulfill({ status: 503, json: { status: 'DOWN', service: 'pitchpulse', database: 'DOWN' } });
    } else {
      await route.fulfill({ json: { status: 'UP', service: 'pitchpulse', database: 'UP' } });
    }
  });
  await page.goto('/');
  await expect(page.getByRole('status')).toContainText(greek.connectivity.loading.title);
  await expect(page.getByRole('button')).toBeDisabled();
  releaseFirst();
  await expect(page.getByRole('status')).toContainText(greek.connectivity.error.title);
  await page.getByRole('button', { name: greek.connectivity.retry }).click();
  await expect(page.getByRole('status')).toContainText(greek.connectivity.ready.title);
});
