import { DOCUMENT } from '@angular/common';
import { inject, Injectable, signal } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { TranslocoService } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';

export type Language = 'el-GR' | 'en-US';
export const LANGUAGE_STORAGE_KEY = 'pitchpulse.language';
export const DEFAULT_LANGUAGE: Language = 'el-GR';

@Injectable({ providedIn: 'root' })
export class LocalizationService {
  private readonly transloco = inject(TranslocoService);
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly activeLanguage = signal<Language>(DEFAULT_LANGUAGE);
  readonly language = this.activeLanguage.asReadonly();
  readonly pending = signal(false);
  readonly loadFailed = signal(false);
  private requestId = 0;

  async initialize(): Promise<void> {
    // Cache the bundled fallback before loading a stored preference.
    await firstValueFrom(this.transloco.load(DEFAULT_LANGUAGE));
    let preferred: string | null = null;
    try {
      preferred = this.document.defaultView?.localStorage.getItem(LANGUAGE_STORAGE_KEY) ?? null;
    } catch {
      // Blocked storage must not prevent reading the page or changing language.
    }
    await this.setLanguage(preferred === 'en-US' ? 'en-US' : DEFAULT_LANGUAGE);
  }

  async setLanguage(language: Language): Promise<void> {
    const request = ++this.requestId;
    this.pending.set(true);
    let selected = language === 'en-US' ? language : DEFAULT_LANGUAGE;
    let failed = false;
    try {
      await firstValueFrom(this.transloco.load(selected));
    } catch {
      selected = DEFAULT_LANGUAGE;
      failed = true;
    }
    if (request !== this.requestId) return;
    this.transloco.setActiveLang(selected);
    this.activeLanguage.set(selected);
    this.document.documentElement.lang = selected;
    this.title.setTitle(this.transloco.translate('metadata.title', {}, selected));
    this.meta.updateTag({ name: 'description', content: this.transloco.translate<string>('metadata.description', {}, selected) });
    this.loadFailed.set(failed);
    try {
      this.document.defaultView?.localStorage.setItem(LANGUAGE_STORAGE_KEY, selected);
    } catch {
      // Preference remains valid for this session when persistence is unavailable.
    }
    this.pending.set(false);
  }
}
