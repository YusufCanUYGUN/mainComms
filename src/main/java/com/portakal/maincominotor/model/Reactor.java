package com.portakal.maincominotor.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "reactors")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Reactor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String name;

    // OpenComputers reactor component address
    @Column(nullable = false)
    private String address;

    // Server control mode: DISABLED (never run), FORCE_ACTIVE (always run), AUTO (battery-based)
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ControlMode controlMode = ControlMode.AUTO;

    // Runtime status data (updated by Lua client)
    private int heatLevel;
    private long euOutput;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReactorStatus status = ReactorStatus.OFFLINE;

    private LocalDateTime lastSeen;

    // Redstone control configuration
    // OpenComputers redstone I/O component address
    private String redstoneAddress;

    // Side of redstone I/O connected to reactor (0=bottom, 1=top, 2=north, 3=south, 4=west, 5=east)
    private Integer redstoneSide;

    // Fuel rod configuration
    // Comma-separated slot numbers where fuel rods go (e.g., "0,1,2,3")
    @Column(length = 500)
    private String fuelSlots;

    // Item name for fuel rods (e.g., "IC2:reactorUraniumQuad")
    private String fuelType;

    // Cooling cell configuration
    // Comma-separated slot numbers where cooling cells go (e.g., "4,5,6,7")
    @Column(length = 500)
    private String coolingSlots;

    // Item name for cooling cells (e.g., "IC2:reactorCoolantSix")
    private String coolingType;

    // Transposer/inventory address for refueling
    private String transposerAddress;

    // Side of transposer facing reactor (for inserting items)
    private Integer transposerReactorSide;

    // Side of transposer facing storage (for pulling items)
    private Integer transposerStorageSide;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
