package gr.pitchpulse;

import static org.assertj.core.api.Assertions.assertThat;

import gr.pitchpulse.health.HealthController.HealthResponse;
import java.sql.DriverManager;
import java.util.List;
import java.util.Map;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.client.RestClient;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
class FlywayRestartIT {
    // Match Compose: the username becomes a schema name during V1. A user named
    // "test" would keep resolving public and would not reproduce the restart bug.
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.10-alpine")
            .withUsername("pitchpulse")
            .withDatabaseName("pitchpulse");

    @Test
    void freshStartupAndNewApplicationContextUseTheSameHistoryAndPreserveData() throws Exception {
        assertThat(connectionDefaultSchema()).isEqualTo("public");
        List<Map<String, Object>> originalHistory;
        try (var first = startApplication()) {
            assertReady(first);
            JdbcTemplate jdbc = first.getBean(JdbcTemplate.class);
            originalHistory = history(jdbc);
            assertThat(originalHistory).hasSize(1);
            // Only this disposable test database receives probe data.
            jdbc.execute("CREATE TABLE pitchpulse.restart_probe (value text NOT NULL)");
            jdbc.update("INSERT INTO pitchpulse.restart_probe (value) VALUES (?)", "preserve across restart");
        }

        // A genuinely new connection now resolves the username-matching schema.
        assertThat(connectionDefaultSchema()).isEqualTo("pitchpulse");
        try (var restarted = startApplication()) {
            assertReady(restarted);
            JdbcTemplate jdbc = restarted.getBean(JdbcTemplate.class);
            assertThat(history(jdbc)).isEqualTo(originalHistory);
            assertThat(restarted.getBean(Flyway.class).getConfiguration().getDefaultSchema()).isEqualTo("public");
            assertThat(jdbc.queryForObject("SELECT value FROM pitchpulse.restart_probe", String.class))
                    .isEqualTo("preserve across restart");
            assertThat(jdbc.queryForObject(
                    "SELECT to_regclass('pitchpulse.flyway_schema_history')::text", String.class)).isNull();
            restarted.getBean(Flyway.class).validate();
        }
    }

    private ServletWebServerApplicationContext startApplication() {
        // Deliberately do not override any Flyway settings: test application.yml.
        return (ServletWebServerApplicationContext) new SpringApplicationBuilder(PitchPulseApplication.class)
                .run("--spring.datasource.url=" + POSTGRES.getJdbcUrl(),
                        "--spring.datasource.username=" + POSTGRES.getUsername(),
                        "--spring.datasource.password=" + POSTGRES.getPassword(),
                        "--server.port=0", "--server.address=127.0.0.1",
                        "--spring.main.banner-mode=off", "--logging.level.root=WARN", "--debug=false");
    }

    private void assertReady(ServletWebServerApplicationContext context) {
        var response = RestClient.create("http://127.0.0.1:" + context.getWebServer().getPort())
                .get().uri("/api/v1/health").retrieve().toEntity(HealthResponse.class);
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isEqualTo(new HealthResponse("UP", "pitchpulse", "UP"));
    }

    private List<Map<String, Object>> history(JdbcTemplate jdbc) {
        return jdbc.queryForList("SELECT * FROM public.flyway_schema_history ORDER BY installed_rank");
    }

    private String connectionDefaultSchema() throws Exception {
        try (var connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             var statement = connection.createStatement();
             var result = statement.executeQuery("SELECT current_schema()")) {
            assertThat(result.next()).isTrue();
            return result.getString(1);
        }
    }
}
