import { Component, inject } from '@angular/core';
import { TranslocoDirective } from '@jsverse/transloco';
import { LocalizationService } from './localization.service';

@Component({
  selector: 'app-language-switcher',
  imports: [TranslocoDirective],
  template: `
    <div *transloco="let t">
      <div class="flex flex-wrap items-center gap-3">
        <label for="site-language" class="text-sm text-muted">{{ t('language.label') }}</label>
        <select id="site-language" [value]="localization.language()"
          [attr.aria-busy]="localization.pending()"
          (change)="changeLanguage($event)"
          class="min-h-12 rounded-lg border border-control-border bg-surface px-3 py-2 text-sm">
          <option value="el-GR" lang="el-GR">{{ t('language.greek') }}</option>
          <option value="en-US" lang="en-US">{{ t('language.english') }}</option>
        </select>
      </div>
      @if (localization.loadFailed()) {
        <p role="alert" class="mt-2 max-w-sm text-sm text-warning">{{ t('language.loadError') }}</p>
      }
    </div>
  `
})
export class LanguageSwitcher {
  readonly localization = inject(LocalizationService);

  changeLanguage(event: Event): void {
    const select = event.target as HTMLSelectElement;
    const language = select.value === 'en-US' ? 'en-US' : 'el-GR';
    // Keep keyboard focus and allow a newer choice to supersede a slow request.
    void this.localization.setLanguage(language).then(() => {
      select.value = this.localization.language();
    });
  }
}
