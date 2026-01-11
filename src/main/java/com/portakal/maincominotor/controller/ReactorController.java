package com.portakal.maincominotor.controller;

import com.portakal.maincominotor.dto.*;
import com.portakal.maincominotor.model.ControlMode;
import com.portakal.maincominotor.model.Reactor;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.service.ConfigService;
import com.portakal.maincominotor.service.ReactorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/opencomputers/reactormenagementV1")
@RequiredArgsConstructor
public class ReactorController {

    private final ReactorService reactorService;
    private final ConfigService configService;

    @GetMapping("/reactors")
    public ResponseEntity<ApiResponse<List<ReactorDTO>>> getAllReactors(Authentication authentication) {
        User user = getCurrentUser(authentication);
        List<ReactorDTO> reactors = reactorService.getReactorsByUser(user).stream()
                .map(ReactorDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(reactors));
    }

    @GetMapping("/reactors/{id}")
    public ResponseEntity<ApiResponse<ReactorDTO>> getReactor(@PathVariable Long id,
                                                               Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.getReactor(id, user)
                .map(reactor -> ResponseEntity.ok(ApiResponse.success(ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/reactors")
    public ResponseEntity<ApiResponse<ReactorDTO>> registerReactor(
            @Valid @RequestBody ReactorRegistrationRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        try {
            Reactor reactor = reactorService.registerReactor(user, request);
            return ResponseEntity.ok(ApiResponse.success("Reactor registered", ReactorDTO.fromEntity(reactor)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PutMapping("/reactors/{id}")
    public ResponseEntity<ApiResponse<ReactorDTO>> updateReactor(@PathVariable Long id,
                                                                  @RequestBody ReactorUpdateRequest request,
                                                                  Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.updateReactorData(id, user, request.getHeatLevel(), request.getEuOutput(), request.getStatus())
                .map(reactor -> ResponseEntity.ok(ApiResponse.success(ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/reactors/address/{address}")
    public ResponseEntity<ApiResponse<ReactorDTO>> updateReactorByAddress(
            @PathVariable String address,
            @RequestBody ReactorUpdateRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.updateReactorDataByAddress(address, user, request.getHeatLevel(), request.getEuOutput(), request.getStatus())
                .map(reactor -> ResponseEntity.ok(ApiResponse.success(ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Update reactor configuration (name, redstone, fuel, cooling, transposer settings).
     */
    @PatchMapping("/reactors/{id}/config")
    public ResponseEntity<ApiResponse<ReactorDTO>> updateReactorConfig(
            @PathVariable Long id,
            @RequestBody ReactorRegistrationRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.updateReactorConfig(id, user, request)
                .map(reactor -> ResponseEntity.ok(ApiResponse.success("Reactor configuration updated", ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Set control mode to DISABLED (reactor never runs).
     */
    @PostMapping("/reactors/{id}/disable")
    public ResponseEntity<ApiResponse<ReactorDTO>> disableReactor(@PathVariable Long id,
                                                                   Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.setControlMode(id, user, ControlMode.DISABLED)
                .map(reactor -> ResponseEntity.ok(ApiResponse.success("Reactor disabled", ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Set control mode to AUTO (normal battery-based operation).
     */
    @PostMapping("/reactors/{id}/auto")
    public ResponseEntity<ApiResponse<ReactorDTO>> setAutoMode(@PathVariable Long id,
                                                                Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.setControlMode(id, user, ControlMode.AUTO)
                .map(reactor -> ResponseEntity.ok(ApiResponse.success("Reactor set to auto mode", ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Set control mode to FORCE_ACTIVE (reactor always runs, ignoring battery level).
     */
    @PostMapping("/reactors/{id}/force-active")
    public ResponseEntity<ApiResponse<ReactorDTO>> setForceActiveMode(@PathVariable Long id,
                                                                       Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.setControlMode(id, user, ControlMode.FORCE_ACTIVE)
                .map(reactor -> ResponseEntity.ok(ApiResponse.success("Reactor set to force active mode", ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Set control mode directly via request body (by ID).
     */
    @PostMapping("/reactors/{id}/control-mode")
    public ResponseEntity<ApiResponse<ReactorDTO>> setControlMode(
            @PathVariable Long id,
            @RequestBody ControlModeRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.setControlMode(id, user, request.getControlMode())
                .map(reactor -> ResponseEntity.ok(ApiResponse.success("Control mode updated", ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Set control mode by address (used by Lua client).
     */
    @PostMapping("/reactors/address/{address}/control-mode")
    public ResponseEntity<ApiResponse<ReactorDTO>> setControlModeByAddress(
            @PathVariable String address,
            @RequestBody ControlModeRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        return reactorService.getReactorByAddress(address, user)
                .flatMap(reactor -> reactorService.setControlMode(reactor.getId(), user, request.getControlMode()))
                .map(reactor -> ResponseEntity.ok(ApiResponse.success("Control mode updated", ReactorDTO.fromEntity(reactor))))
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/reactors/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteReactor(@PathVariable Long id,
                                                            Authentication authentication) {
        User user = getCurrentUser(authentication);
        reactorService.deleteReactor(id, user);
        return ResponseEntity.ok(ApiResponse.success("Reactor deleted", null));
    }

    @GetMapping("/config")
    public ResponseEntity<ApiResponse<List<ConfigDTO>>> getConfigs() {
        List<ConfigDTO> configs = configService.getAllConfigs().stream()
                .map(ConfigDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(configs));
    }

    @GetMapping("/config/{key}")
    public ResponseEntity<ApiResponse<ConfigDTO>> getConfig(@PathVariable String key) {
        return configService.getConfig(key)
                .map(config -> ResponseEntity.ok(ApiResponse.success(ConfigDTO.fromEntity(config))))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/config/{key}")
    public ResponseEntity<ApiResponse<ConfigDTO>> setConfig(@PathVariable String key,
                                                             @RequestBody ConfigDTO config) {
        var savedConfig = configService.setConfig(key, config.getValue(), config.getDescription());
        return ResponseEntity.ok(ApiResponse.success(ConfigDTO.fromEntity(savedConfig)));
    }

    private User getCurrentUser(Authentication authentication) {
        Object principal = authentication.getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        throw new RuntimeException("Invalid authentication");
    }
}
