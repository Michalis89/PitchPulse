package gr.pitchpulse.config;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class ApiWebConfiguration implements WebMvcConfigurer {
    private final List<String> allowedOrigins;

    public ApiWebConfiguration(@Value("${app.cors.allowed-origins}") List<String> allowedOrigins) {
        if (allowedOrigins.stream().anyMatch(origin -> origin.contains("*"))) {
            throw new IllegalArgumentException("CORS requires explicit origins");
        }
        this.allowedOrigins = List.copyOf(allowedOrigins);
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/v1/**")
                .allowedOrigins(allowedOrigins.toArray(String[]::new))
                .allowedMethods("GET")
                .allowCredentials(false);
    }
}
