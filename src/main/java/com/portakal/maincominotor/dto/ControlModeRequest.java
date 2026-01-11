package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.ControlMode;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ControlModeRequest {

    @NotNull(message = "Control mode is required")
    private ControlMode controlMode;
}