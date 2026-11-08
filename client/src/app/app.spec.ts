import { TestBed } from '@angular/core/testing';
import { App } from './app';
import { provideRouter, Router } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { routes } from './app.routes';
import { provideI18n } from './i18n/i18n.providers';
import { LocalizationService } from './i18n/localization.service';
import greek from '../../public/i18n/el-GR.json';

describe('App', () => {
  beforeEach(async () => {
    localStorage.clear();
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [provideRouter(routes), provideHttpClient(), provideHttpClientTesting(), provideI18n()],
    }).compileComponents();
    await TestBed.inject(LocalizationService).initialize();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('loads the foundation route and requests backend health', async () => {
    const fixture = TestBed.createComponent(App);
    const router = TestBed.inject(Router);
    await router.navigateByUrl('/');
    fixture.detectChanges();
    TestBed.inject(HttpTestingController).expectOne('/api/v1/health').flush({
      status: 'UP', service: 'pitchpulse', database: 'UP'
    });
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain(greek.home.title);
    expect(compiled.textContent).toContain(greek.connectivity.ready.title);
    TestBed.inject(HttpTestingController).verify();
  });
});
