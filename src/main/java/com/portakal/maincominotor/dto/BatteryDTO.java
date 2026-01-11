package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.Battery;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
public class BatteryDTO {

    private Long id;
    private String name;
    private String address;
    private long currentEU;
    private long maxEU;
    private int chargePercent;
    private LocalDateTime lastUpdated;

    public static BatteryDTO fromEntity(Battery battery) {
        BatteryDTO dto = new BatteryDTO();
        dto.setId(battery.getId());
        dto.setName(battery.getName());
        dto.setAddress(battery.getAddress());
        dto.setCurrentEU(battery.getCurrentEU());
        dto.setMaxEU(battery.getMaxEU());
        dto.setChargePercent(battery.getChargePercent());
        dto.setLastUpdated(battery.getLastUpdated());
        return dto;
    }
}
