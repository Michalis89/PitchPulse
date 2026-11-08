package gr.pitchpulse.health;

import org.springframework.dao.DataAccessException;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    private final JdbcTemplate jdbc;

    public HealthController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/api/v1/health")
    public ResponseEntity<HealthResponse> health() {
        try {
            Integer result = jdbc.queryForObject("SELECT 1", Integer.class);
            if (Integer.valueOf(1).equals(result)) {
                return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                        .body(new HealthResponse("UP", "pitchpulse", "UP"));
            }
        } catch (DataAccessException ignored) {
            // Public readiness response intentionally contains no database details.
        }
        return ResponseEntity.status(503).cacheControl(CacheControl.noStore())
                .body(new HealthResponse("DOWN", "pitchpulse", "DOWN"));
    }

    public record HealthResponse(String status, String service, String database) {}
}
