package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.ControlMode;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ReactorRegistrationRequest {

    @NotBlank(message = "Name is required")
    private String name;

    @NotBlank(message = "Reactor component address is required")
    private String address;

    // Redstone control configuration
    private String redstoneAddress;
    private Integer redstoneSide;

    // Fuel configuration
    private String fuelSlots;
    private String fuelType;

    // Cooling configuration
    private String coolingSlots;
    private String coolingType;

    // Transposer configuration for refueling
    private String transposerAddress;
    private Integer transposerReactorSide;
    private Integer transposerStorageSide;

    // Initial control mode (defaults to AUTO)
    private ControlMode controlMode = ControlMode.AUTO;
}
