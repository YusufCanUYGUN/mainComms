package com.portakal.maincominotor.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ApiKeyCreateRequest {

    @NotBlank(message = "Name is required")
    private String name;
}
