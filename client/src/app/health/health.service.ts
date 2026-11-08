import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, timeout } from 'rxjs';

// Contract: docs/openapi.yaml. No match or source data is served in this slice.
export interface HealthResponse {
  status: 'UP' | 'DOWN';
  service: 'pitchpulse';
  database: 'UP' | 'DOWN';
}

@Injectable({ providedIn: 'root' })
export class HealthService {
  private readonly http = inject(HttpClient);

  getHealth(): Observable<HealthResponse> {
    return this.http.get<HealthResponse>('/api/v1/health').pipe(timeout(5000));
  }
}
