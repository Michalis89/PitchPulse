import { Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { HealthService } from '../health/health.service';
import { TranslocoDirective } from '@jsverse/transloco';
import { TranslocoDatePipe } from '@jsverse/transloco-locale';
import { LanguageSwitcher } from '../i18n/language-switcher';

@Component({
  selector: 'app-home',
  imports: [TranslocoDirective, TranslocoDatePipe, LanguageSwitcher],
  templateUrl: './home.html'
})
export class Home {
  private readonly health = inject(HealthService);
  private readonly destroyRef = inject(DestroyRef);
  readonly state = signal<'loading' | 'ready' | 'error'>('loading');
  readonly checkedAt = signal<Date | null>(null);

  constructor() {
    this.refresh();
  }

  refresh(): void {
    this.state.set('loading');
    this.health.getHealth().pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: (response) => {
        this.state.set(response.status === 'UP' && response.database === 'UP' ? 'ready' : 'error');
        this.checkedAt.set(new Date());
      },
      error: () => {
        this.state.set('error');
        this.checkedAt.set(new Date());
      }
    });
  }
}
