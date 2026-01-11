package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.ControlMode;
import com.portakal.maincominotor.model.Reactor;
import com.portakal.maincominotor.model.ReactorStatus;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
public class ReactorDTO {

    private Long id;
    private String name;
    private String address;
    private ControlMode controlMode;
    private int heatLevel;
    private long euOutput;
    private ReactorStatus status;
    private LocalDateTime lastSeen;

    // Redstone control configuration
    private String redstoneAddress;
    private Integer redstoneSide;

    // Fuel configuration
    private String fuelSlots;
    private String fuelType;

    // Cooling configuration
    private String coolingSlots;
    private String coolingType;

    // Transposer configuration
    private String transposerAddress;
    private Integer transposerReactorSide;
    private Integer transposerStorageSide;

    /**
     * Returns true if reactor should be active based on control mode.
     * DISABLED = never active, FORCE_ACTIVE = always active, AUTO = depends on battery
     */
    public boolean isEnabled() {
        return controlMode != ControlMode.DISABLED;
    }

    public static ReactorDTO fromEntity(Reactor reactor) {
        ReactorDTO dto = new ReactorDTO();
        dto.setId(reactor.getId());
        dto.setName(reactor.getName());
        dto.setAddress(reactor.getAddress());
        dto.setControlMode(reactor.getControlMode());
        dto.setHeatLevel(reactor.getHeatLevel());
        dto.setEuOutput(reactor.getEuOutput());
        dto.setStatus(reactor.getStatus());
        dto.setLastSeen(reactor.getLastSeen());
        dto.setRedstoneAddress(reactor.getRedstoneAddress());
        dto.setRedstoneSide(reactor.getRedstoneSide());
        dto.setFuelSlots(reactor.getFuelSlots());
        dto.setFuelType(reactor.getFuelType());
        dto.setCoolingSlots(reactor.getCoolingSlots());
        dto.setCoolingType(reactor.getCoolingType());
        dto.setTransposerAddress(reactor.getTransposerAddress());
        dto.setTransposerReactorSide(reactor.getTransposerReactorSide());
        dto.setTransposerStorageSide(reactor.getTransposerStorageSide());
        return dto;
    }
}
