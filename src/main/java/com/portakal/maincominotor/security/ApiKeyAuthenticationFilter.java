package com.portakal.maincominotor.security;

import com.portakal.maincominotor.model.ApiKey;
import com.portakal.maincominotor.repository.ApiKeyRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class ApiKeyAuthenticationFilter extends OncePerRequestFilter {

    private static final String API_KEY_HEADER = "X-API-Key";

    private final ApiKeyRepository apiKeyRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String apiKeyValue = request.getHeader(API_KEY_HEADER);

        if (apiKeyValue != null && !apiKeyValue.isBlank()) {
            Optional<ApiKey> apiKeyOpt = apiKeyRepository.findByKeyValueAndEnabledTrue(apiKeyValue);

            if (apiKeyOpt.isPresent()) {
                ApiKey apiKey = apiKeyOpt.get();

                // Update last used timestamp
                apiKey.setLastUsed(LocalDateTime.now());
                apiKeyRepository.save(apiKey);

                // Create authentication token with user info
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                apiKey.getUser(),
                                null,
                                Collections.singletonList(new SimpleGrantedAuthority("ROLE_API"))
                        );

                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        filterChain.doFilter(request, response);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        // Only apply to API endpoints
        return !path.startsWith("/opencomputers");
    }
}
