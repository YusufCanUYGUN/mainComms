package com.portakal.maincominotor.dto;

import lombok.Data;

@Data
public class BatteryUpdateRequest {

    private long currentEU;
    private long maxEU;
}
