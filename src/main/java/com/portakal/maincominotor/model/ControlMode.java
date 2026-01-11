package com.portakal.maincominotor.model;

/**
 * Control mode for reactor management from the server.
 */
public enum ControlMode {
    /**
     * Reactor will never start, regardless of battery level.
     * Used for maintenance or safety lockout.
     */
    DISABLED,

    /**
     * Reactor will always run (if safe), ignoring battery level.
     * Used when you need maximum power regardless of storage.
     */
    FORCE_ACTIVE,

    /**
     * Normal operation: reactor runs based on battery level.
     * Uses gradual scaling between 20-90% battery.
     */
    AUTO
}