import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { Home } from './home';
import { provideI18n } from '../i18n/i18n.providers';
import { LocalizationService } from '../i18n/localization.service';
import greek from '../../../public/i18n/el-GR.json';

describe('Foundation connection', () => {
  beforeEach(async () => {
    localStorage.clear();
    TestBed.configureTestingModule({
      imports: [Home],
      providers: [provideHttpClient(), provideHttpClientTesting(), provideI18n()]
    });
    await TestBed.inject(LocalizationService).initialize();
  });

  afterEach(() => TestBed.inject(HttpTestingController).verify());

  it('shows loading, reports failure and lets the user retry', async () => {
    const fixture = TestBed.createComponent(Home);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    expect(element.textContent).toContain(greek.connectivity.loading.title);
    expect(element.querySelector('button')?.disabled).toBe(true);

    const http = TestBed.inject(HttpTestingController);
    http.expectOne('/api/v1/health').flush({}, { status: 503, statusText: 'Unavailable' });
    await fixture.whenStable();
    expect(element.textContent).toContain(greek.connectivity.error.title);
    element.querySelector('button')?.click();
    fixture.detectChanges();
    http.expectOne('/api/v1/health').flush({ status: 'UP', service: 'pitchpulse', database: 'UP' });
    await fixture.whenStable();
    expect(element.textContent).toContain(greek.connectivity.ready.title);
  });

  it('does not show ready when the database is down in a response', async () => {
    const fixture = TestBed.createComponent(Home);
    TestBed.inject(HttpTestingController).expectOne('/api/v1/health').flush({
      status: 'UP', service: 'pitchpulse', database: 'DOWN'
    });
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).textContent).toContain(greek.connectivity.error.title);
  });
});
