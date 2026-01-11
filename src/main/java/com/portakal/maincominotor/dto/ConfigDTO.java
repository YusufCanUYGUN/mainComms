package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.GlobalConfig;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class ConfigDTO {

    private String key;
    private String value;
    private String description;

    public static ConfigDTO fromEntity(GlobalConfig config) {
        ConfigDTO dto = new ConfigDTO();
        dto.setKey(config.getKey());
        dto.setValue(config.getValue());
        dto.setDescription(config.getDescription());
        return dto;
    }
}
