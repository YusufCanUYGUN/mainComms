package com.portakal.maincominotor.dto;

import com.portakal.maincominotor.model.ReactorStatus;
import lombok.Data;

@Data
public class ReactorUpdateRequest {

    private int heatLevel;
    private long euOutput;
    private ReactorStatus status;
}
