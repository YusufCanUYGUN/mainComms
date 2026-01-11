package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.ApiKey;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
public class ApiKeyDTO {

    private Long id;
    private String name;
    private String keyValue; // Only included when first created
    private LocalDateTime createdAt;
    private LocalDateTime lastUsed;
    private boolean enabled;

    public static ApiKeyDTO fromEntity(ApiKey apiKey, boolean includeKey) {
        ApiKeyDTO dto = new ApiKeyDTO();
        dto.setId(apiKey.getId());
        dto.setName(apiKey.getName());
        if (includeKey) {
            dto.setKeyValue(apiKey.getKeyValue());
        }
        dto.setCreatedAt(apiKey.getCreatedAt());
        dto.setLastUsed(apiKey.getLastUsed());
        dto.setEnabled(apiKey.isEnabled());
        return dto;
    }

    public static ApiKeyDTO fromEntity(ApiKey apiKey) {
        return fromEntity(apiKey, false);
    }
}
