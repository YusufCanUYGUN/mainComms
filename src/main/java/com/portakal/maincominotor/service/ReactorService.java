package com.portakal.maincominotor.service;

import com.portakal.maincominotor.dto.ReactorRegistrationRequest;
import com.portakal.maincominotor.model.ControlMode;
import com.portakal.maincominotor.model.Reactor;
import com.portakal.maincominotor.model.ReactorStatus;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.repository.ReactorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ReactorService {

    private final ReactorRepository reactorRepository;

    public List<Reactor> getReactorsByUser(User user) {
        return reactorRepository.findByUser(user);
    }

    public Optional<Reactor> getReactor(Long id, User user) {
        return reactorRepository.findByIdAndUser(id, user);
    }

    public Optional<Reactor> getReactorByAddress(String address, User user) {
        return reactorRepository.findByAddressAndUser(address, user);
    }

    /**
     * Register a new reactor with full configuration for manual control.
     */
    @Transactional
    public Reactor registerReactor(User user, ReactorRegistrationRequest request) {
        if (reactorRepository.existsByAddressAndUser(request.getAddress(), user)) {
            throw new IllegalArgumentException("Reactor with this address already exists");
        }

        Reactor reactor = new Reactor();
        reactor.setUser(user);
        reactor.setName(request.getName());
        reactor.setAddress(request.getAddress());
        reactor.setControlMode(request.getControlMode() != null ? request.getControlMode() : ControlMode.AUTO);
        reactor.setStatus(ReactorStatus.OFFLINE);

        // Redstone control
        reactor.setRedstoneAddress(request.getRedstoneAddress());
        reactor.setRedstoneSide(request.getRedstoneSide());

        // Fuel configuration
        reactor.setFuelSlots(request.getFuelSlots());
        reactor.setFuelType(request.getFuelType());

        // Cooling configuration
        reactor.setCoolingSlots(request.getCoolingSlots());
        reactor.setCoolingType(request.getCoolingType());

        // Transposer configuration
        reactor.setTransposerAddress(request.getTransposerAddress());
        reactor.setTransposerReactorSide(request.getTransposerReactorSide());
        reactor.setTransposerStorageSide(request.getTransposerStorageSide());

        return reactorRepository.save(reactor);
    }

    /**
     * Update reactor runtime data (called by Lua client).
     */
    @Transactional
    public Optional<Reactor> updateReactorData(Long id, User user, int heatLevel, long euOutput, ReactorStatus status) {
        return reactorRepository.findByIdAndUser(id, user)
                .map(reactor -> {
                    reactor.setHeatLevel(heatLevel);
                    reactor.setEuOutput(euOutput);
                    reactor.setStatus(status);
                    reactor.setLastSeen(LocalDateTime.now());
                    return reactorRepository.save(reactor);
                });
    }

    /**
     * Update reactor runtime data by address (called by Lua client).
     */
    @Transactional
    public Optional<Reactor> updateReactorDataByAddress(String address, User user, int heatLevel, long euOutput, ReactorStatus status) {
        return reactorRepository.findByAddressAndUser(address, user)
                .map(reactor -> {
                    reactor.setHeatLevel(heatLevel);
                    reactor.setEuOutput(euOutput);
                    reactor.setStatus(status);
                    reactor.setLastSeen(LocalDateTime.now());
                    return reactorRepository.save(reactor);
                });
    }

    /**
     * Set reactor control mode.
     * DISABLED = never run, FORCE_ACTIVE = always run (safely), AUTO = battery-based control
     */
    @Transactional
    public Optional<Reactor> setControlMode(Long id, User user, ControlMode controlMode) {
        return reactorRepository.findByIdAndUser(id, user)
                .map(reactor -> {
                    reactor.setControlMode(controlMode);
                    return reactorRepository.save(reactor);
                });
    }

    /**
     * Update reactor configuration (redstone, fuel, cooling, transposer settings).
     */
    @Transactional
    public Optional<Reactor> updateReactorConfig(Long id, User user, ReactorRegistrationRequest request) {
        return reactorRepository.findByIdAndUser(id, user)
                .map(reactor -> {
                    if (request.getName() != null) {
                        reactor.setName(request.getName());
                    }
                    if (request.getRedstoneAddress() != null) {
                        reactor.setRedstoneAddress(request.getRedstoneAddress());
                    }
                    if (request.getRedstoneSide() != null) {
                        reactor.setRedstoneSide(request.getRedstoneSide());
                    }
                    if (request.getFuelSlots() != null) {
                        reactor.setFuelSlots(request.getFuelSlots());
                    }
                    if (request.getFuelType() != null) {
                        reactor.setFuelType(request.getFuelType());
                    }
                    if (request.getCoolingSlots() != null) {
                        reactor.setCoolingSlots(request.getCoolingSlots());
                    }
                    if (request.getCoolingType() != null) {
                        reactor.setCoolingType(request.getCoolingType());
                    }
                    if (request.getTransposerAddress() != null) {
                        reactor.setTransposerAddress(request.getTransposerAddress());
                    }
                    if (request.getTransposerReactorSide() != null) {
                        reactor.setTransposerReactorSide(request.getTransposerReactorSide());
                    }
                    if (request.getTransposerStorageSide() != null) {
                        reactor.setTransposerStorageSide(request.getTransposerStorageSide());
                    }
                    if (request.getControlMode() != null) {
                        reactor.setControlMode(request.getControlMode());
                    }
                    return reactorRepository.save(reactor);
                });
    }

    @Transactional
    public void deleteReactor(Long id, User user) {
        reactorRepository.findByIdAndUser(id, user)
                .ifPresent(reactorRepository::delete);
    }
}
