package com.portakal.maincominotor.service;

import com.portakal.maincominotor.model.GlobalConfig;
import com.portakal.maincominotor.repository.GlobalConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ConfigService {

    private final GlobalConfigRepository configRepository;

    public List<GlobalConfig> getAllConfigs() {
        return configRepository.findAll();
    }

    public Optional<GlobalConfig> getConfig(String key) {
        return configRepository.findById(key);
    }

    public String getConfigValue(String key, String defaultValue) {
        return configRepository.findById(key)
                .map(GlobalConfig::getValue)
                .orElse(defaultValue);
    }

    @Transactional
    public GlobalConfig setConfig(String key, String value, String description) {
        GlobalConfig config = configRepository.findById(key)
                .orElse(new GlobalConfig());

        config.setKey(key);
        config.setValue(value);
        if (description != null) {
            config.setDescription(description);
        }

        return configRepository.save(config);
    }

    @Transactional
    public GlobalConfig setConfig(String key, String value) {
        return setConfig(key, value, null);
    }

    @Transactional
    public void deleteConfig(String key) {
        configRepository.deleteById(key);
    }
}
