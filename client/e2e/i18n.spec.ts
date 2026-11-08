import { test, expect, Page } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import greek from '../public/i18n/el-GR.json';
import english from '../public/i18n/en-US.json';

const expectedDate = (page: Page, locale: string) => page.evaluate(language =>
  new Intl.DateTimeFormat(language, {
    year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
    timeZoneName: 'short', timeZone: 'Europe/Athens'
  }).format(new Date('2026-11-08T12:34:00Z')), locale);

// A different browser locale/timezone must not override the application's defaults.
test.use({ locale: 'en-US', timezoneId: 'America/Los_Angeles' });

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date('2026-11-08T12:34:00Z'));
  await page.route('**/api/v1/health', route => route.fulfill({
    json: { status: 'UP', service: 'pitchpulse', database: 'UP' }
  }));
});

test('Greek defaults, metadata and empty state are accessible at every viewport', async ({ page }, testInfo) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('lang', 'el-GR');
  await expect(page).toHaveTitle(greek.metadata.title);
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Καθαρή εικόνα του αγώνα.');
  await expect(page.getByRole('option', { name: 'Ελληνικά', exact: true })).toHaveText('Ελληνικά');
  await expect(page.getByRole('combobox', { name: greek.language.label })).toHaveValue('el-GR');
  await expect(page.getByRole('contentinfo')).toHaveText(greek.empty.foundation);
  await expect(page.getByRole('status')).toContainText(greek.connectivity.ready.title);
  await expect(page.locator('time')).toHaveText(await expectedDate(page, 'el-GR'));
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath('i18n-greek.png'), fullPage: true });
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
});

test('switches at runtime, preserves focus and survives reloads in both directions', async ({ page }, testInfo) => {
  await page.goto('/');
  const switcher = page.getByRole('combobox');
  await switcher.focus();
  await switcher.selectOption('en-US');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(english.home.title);
  await expect(switcher).toBeFocused();
  await expect(page.locator('html')).toHaveAttribute('lang', 'en-US');
  await expect(page).toHaveTitle(english.metadata.title);
  await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', english.metadata.description);
  await expect(switcher).toHaveAccessibleName(english.language.label);
  expect(await page.evaluate(() => localStorage.getItem('pitchpulse.language'))).toBe('en-US');
  await expect(page.locator('time')).toHaveText(await expectedDate(page, 'en-US'));
  await expect(page.getByRole('contentinfo')).toHaveText(english.empty.foundation);
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  await expect(page.locator('section[aria-labelledby="connection-title"]')).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath('i18n-english.png'), fullPage: true });
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
  await page.reload();
  await expect(page.getByRole('combobox')).toHaveValue('en-US');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(english.home.title);
  await page.getByRole('combobox').selectOption('el-GR');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
  await page.reload();
  await expect(page.getByRole('combobox')).toHaveValue('el-GR');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
});

test('missing and empty English values fall back to Greek after switching and reload', async ({ page }) => {
  const partial = structuredClone(english);
  Reflect.deleteProperty(partial.home, 'title');
  partial.connectivity.ready.body = '';
  await page.route('**/i18n/en-US.json', route => route.fulfill({ json: partial }));
  await page.goto('/');
  await page.getByRole('combobox').selectOption('en-US');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en-US');
  await expect(page.getByRole('status')).toContainText(english.connectivity.ready.title);
  await expect(page.getByRole('status')).toContainText(greek.connectivity.ready.body);
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
  await page.reload();
  await expect(page.getByRole('combobox')).toHaveValue('en-US');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
});

test('unavailable English asset returns to Greek and stores the fallback', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('pitchpulse.language', 'en-US'));
  await page.route('**/i18n/en-US.json', route => route.fulfill({ status: 503, body: '' }));
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
  await expect(page.getByRole('combobox')).toHaveValue('el-GR');
  await expect(page.getByRole('alert')).toHaveText(greek.language.loadError);
  expect(await page.evaluate(() => localStorage.getItem('pitchpulse.language'))).toBe('el-GR');
});

test('unsupported stored language is safely replaced with Greek', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('pitchpulse.language', 'not-supported'));
  await page.goto('/');
  await expect(page.getByRole('combobox')).toHaveValue('el-GR');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(greek.home.title);
  expect(await page.evaluate(() => localStorage.getItem('pitchpulse.language'))).toBe('el-GR');
});
