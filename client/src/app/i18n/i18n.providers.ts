import { inject, Injectable, isDevMode } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { provideTransloco, Translation, TranslocoLoader } from '@jsverse/transloco';
import { provideTranslocoLocale } from '@jsverse/transloco-locale';
import { of, timeout } from 'rxjs';
import greek from '../../../public/i18n/el-GR.json';
import { DEFAULT_LANGUAGE } from './localization.service';

export const DISPLAY_TIMEZONE = 'Europe/Athens';
export const DATE_FORMAT = {
  year: 'numeric', month: 'short', day: 'numeric',
  hour: '2-digit', minute: '2-digit', timeZoneName: 'short', timeZone: DISPLAY_TIMEZONE
} as const satisfies Intl.DateTimeFormatOptions;

@Injectable({ providedIn: 'root' })
export class TranslationLoader implements TranslocoLoader {
  private readonly http = inject(HttpClient);

  getTranslation(language: string) {
    // Greek is always available, even if optional language assets fail to load.
    return language === DEFAULT_LANGUAGE
      ? of<Translation>(greek)
      : this.http.get<Translation>(`i18n/${language}.json`).pipe(timeout(4000));
  }
}

export function provideI18n() {
  return [
    provideTransloco({
      config: {
        availableLangs: ['el-GR', 'en-US'],
        defaultLang: DEFAULT_LANGUAGE,
        fallbackLang: DEFAULT_LANGUAGE,
        reRenderOnLangChange: true,
        failedRetries: 0,
        missingHandler: { useFallbackTranslation: true, allowEmpty: false, logMissingKey: isDevMode() },
        prodMode: !isDevMode()
      },
      loader: TranslationLoader
    }),
    provideTranslocoLocale({
      defaultLocale: DEFAULT_LANGUAGE,
      langToLocaleMapping: { 'el-GR': 'el-GR', 'en-US': 'en-US' },
      localeConfig: { global: { date: DATE_FORMAT } }
    })
  ];
}
