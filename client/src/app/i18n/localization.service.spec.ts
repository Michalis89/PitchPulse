import { TestBed } from '@angular/core/testing';
import { Component } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TranslocoDatePipe, TranslocoDecimalPipe } from '@jsverse/transloco-locale';
import { provideI18n, DATE_FORMAT } from './i18n.providers';
import { LANGUAGE_STORAGE_KEY, LocalizationService } from './localization.service';
import greek from '../../../public/i18n/el-GR.json';
import english from '../../../public/i18n/en-US.json';

@Component({
  imports: [TranslocoDatePipe, TranslocoDecimalPipe],
  template: `
    <time data-season="winter">{{ winter | translocoDate }}</time>
    <time data-season="summer">{{ summer | translocoDate }}</time>
    <span>{{ amount | translocoDecimal }}</span>
  `
})
class FormatHost {
  readonly winter = new Date('2026-01-08T12:30:00Z');
  readonly summer = new Date('2026-07-08T12:30:00Z');
  readonly amount = 12345.67;
}

describe('Runtime localization', () => {
  let localization: LocalizationService;
  let http: HttpTestingController;

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({
      imports: [FormatHost],
      providers: [provideHttpClient(), provideHttpClientTesting(), provideI18n()]
    });
    localization = TestBed.inject(LocalizationService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    http.verify();
    vi.restoreAllMocks();
    localStorage.clear();
  });

  it('defaults to Greek regardless of the browser language and localizes metadata', async () => {
    await localization.initialize();
    expect(localization.language()).toBe('el-GR');
    expect(document.documentElement.lang).toBe('el-GR');
    expect(document.title).toBe(greek.metadata.title);
    expect(document.querySelector('meta[name="description"]')?.getAttribute('content')).toBe(greek.metadata.description);
    expect(TestBed.inject(TranslocoService).translate('home.title')).toBe(greek.home.title);
  });

  it('restores saved English, updates metadata, and persists later switches', async () => {
    localStorage.setItem(LANGUAGE_STORAGE_KEY, 'en-US');
    const initialized = localization.initialize();
    // initialize awaits the synchronous bundled Greek load before the stored preference.
    await Promise.resolve();
    http.expectOne('i18n/en-US.json').flush(english);
    await initialized;
    expect(localization.language()).toBe('en-US');
    expect(document.documentElement.lang).toBe('en-US');
    expect(document.title).toBe(english.metadata.title);
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('en-US');
    await localization.setLanguage('el-GR');
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('el-GR');
  });

  it('ignores unsupported preferences', async () => {
    localStorage.setItem(LANGUAGE_STORAGE_KEY, 'unsupported-locale');
    await localization.initialize();
    expect(localization.language()).toBe('el-GR');
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('el-GR');
  });

  it('keeps language switching usable when storage reads and writes are blocked', async () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => { throw new Error('blocked'); });
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => { throw new Error('blocked'); });
    await localization.initialize();
    const switched = localization.setLanguage('en-US');
    http.expectOne('i18n/en-US.json').flush(english);
    await switched;
    expect(localization.language()).toBe('en-US');
    expect(document.documentElement.lang).toBe('en-US');
  });

  it('uses Greek for missing or empty English keys while keeping the selected locale', async () => {
    await localization.initialize();
    const switched = localization.setLanguage('en-US');
    const partial = structuredClone(english);
    partial.home.title = '';
    Reflect.deleteProperty(partial.connectivity.ready, 'body');
    http.expectOne('i18n/en-US.json').flush(partial);
    await switched;
    const translator = TestBed.inject(TranslocoService);
    expect(translator.translate('home.title')).toBe(greek.home.title);
    expect(translator.translate('connectivity.ready.body')).toBe(greek.connectivity.ready.body);
    expect(localization.language()).toBe('en-US');
  });

  it('returns to Greek if the English asset cannot be loaded', async () => {
    await localization.initialize();
    const switched = localization.setLanguage('en-US');
    http.expectOne('i18n/en-US.json').flush({}, { status: 503, statusText: 'Unavailable' });
    await switched;
    expect(localization.language()).toBe('el-GR');
    expect(localization.loadFailed()).toBe(true);
    expect(localization.pending()).toBe(false);
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('el-GR');
    expect(TestBed.inject(TranslocoService).translate('home.title')).toBe(greek.home.title);
  });

  it('does not let a slow English load override a newer Greek choice', async () => {
    await localization.initialize();
    const englishSwitch = localization.setLanguage('en-US');
    await localization.setLanguage('el-GR');
    http.expectOne('i18n/en-US.json').flush(english);
    await englishSwitch;
    expect(localization.language()).toBe('el-GR');
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('el-GR');
  });

  it('localizes numbers and date/time with Athens winter and summer offsets', async () => {
    await localization.initialize();
    const fixture = TestBed.createComponent(FormatHost);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    expect(element.querySelector('span')?.textContent).toBe('12.345,67');
    expect(element.querySelector('[data-season="winter"]')?.textContent)
      .toBe(new Intl.DateTimeFormat('el-GR', DATE_FORMAT).format(fixture.componentInstance.winter));
    expect(element.querySelector('[data-season="summer"]')?.textContent)
      .toBe(new Intl.DateTimeFormat('el-GR', DATE_FORMAT).format(fixture.componentInstance.summer));
    const switched = localization.setLanguage('en-US');
    http.expectOne('i18n/en-US.json').flush(english);
    await switched;
    await fixture.whenStable();
    expect(element.querySelector('span')?.textContent).toBe('12,345.67');
    expect(element.querySelector('[data-season="winter"]')?.textContent)
      .toBe(new Intl.DateTimeFormat('en-US', DATE_FORMAT).format(fixture.componentInstance.winter));
    expect(element.querySelector('[data-season="summer"]')?.textContent)
      .toBe(new Intl.DateTimeFormat('en-US', DATE_FORMAT).format(fixture.componentInstance.summer));
    expect(DATE_FORMAT.timeZone).toBe('Europe/Athens');
  });
});

describe('Shipped translation dictionaries', () => {
  function leafKeys(value: Record<string, unknown>, prefix = ''): string[] {
    return Object.entries(value).flatMap(([key, item]) => {
      const path = prefix ? `${prefix}.${key}` : key;
      if (typeof item === 'object' && item !== null) return leafKeys(item as Record<string, unknown>, path);
      expect(typeof item).toBe('string');
      expect(String(item).trim()).not.toBe('');
      return [path];
    }).sort();
  }

  it('ships matching nonempty structured keys in both languages', () => {
    expect(leafKeys(greek)).toEqual(leafKeys(english));
  });

  it('preserves actual Greek Unicode and native language names', () => {
    expect(greek.language.greek).toBe('Ελληνικά');
    expect(english.language.greek).toBe('Ελληνικά');
    expect(greek.home.title).toBe('Καθαρή εικόνα του αγώνα.');
    expect(greek.navigation.skip).toMatch(/[\u0370-\u03ff]/u);
    expect(JSON.stringify(greek)).not.toMatch(/\?{2,}|\ufffd/u);
    expect(JSON.stringify(english)).not.toMatch(/\?{2,}|\ufffd/u);
  });
});
