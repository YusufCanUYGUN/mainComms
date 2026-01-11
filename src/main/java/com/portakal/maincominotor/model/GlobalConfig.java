package com.portakal.maincominotor.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "global_config")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GlobalConfig {

    @Id
    @Column(name = "config_key", nullable = false)
    private String key;

    @Column(nullable = false)
    private String value;

    private String description;
}
