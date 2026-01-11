package com.portakal.maincominotor.service;

import com.portakal.maincominotor.model.ApiKey;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.repository.ApiKeyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ApiKeyService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int KEY_LENGTH = 32;

    private final ApiKeyRepository apiKeyRepository;

    @Transactional
    public ApiKey generateApiKey(User user, String name) {
        String keyValue = generateSecureKey();

        ApiKey apiKey = new ApiKey();
        apiKey.setUser(user);
        apiKey.setName(name);
        apiKey.setKeyValue(keyValue);
        apiKey.setEnabled(true);

        return apiKeyRepository.save(apiKey);
    }

    public Optional<User> validateApiKey(String keyValue) {
        return apiKeyRepository.findByKeyValueAndEnabledTrue(keyValue)
                .map(ApiKey::getUser);
    }

    public List<ApiKey> getUserApiKeys(User user) {
        return apiKeyRepository.findByUser(user);
    }

    public List<ApiKey> getActiveUserApiKeys(User user) {
        return apiKeyRepository.findByUserAndEnabledTrue(user);
    }

    @Transactional
    public void revokeApiKey(Long id, User user) {
        apiKeyRepository.findById(id)
                .filter(key -> key.getUser().getId().equals(user.getId()))
                .ifPresent(key -> {
                    key.setEnabled(false);
                    apiKeyRepository.save(key);
                });
    }

    @Transactional
    public Optional<ApiKey> regenerateApiKey(Long id, User user) {
        return apiKeyRepository.findById(id)
                .filter(key -> key.getUser().getId().equals(user.getId()))
                .map(key -> {
                    key.setKeyValue(generateSecureKey());
                    return apiKeyRepository.save(key);
                });
    }

    @Transactional
    public void deleteApiKey(Long id, User user) {
        apiKeyRepository.findById(id)
                .filter(key -> key.getUser().getId().equals(user.getId()))
                .ifPresent(apiKeyRepository::delete);
    }

    private String generateSecureKey() {
        byte[] bytes = new byte[KEY_LENGTH];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
