package com.portakal.maincominotor.controller;

import com.portakal.maincominotor.dto.*;
import com.portakal.maincominotor.model.Battery;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.service.BatteryService;
import com.portakal.maincominotor.service.ConfigService;
import com.portakal.maincominotor.service.ReactorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/opencomputers/batterymanagement")
@RequiredArgsConstructor
public class BatteryController {

    private final BatteryService batteryService;
    private final ReactorService reactorService;
    private final ConfigService configService;

    @GetMapping("/batteries")
    public ResponseEntity<ApiResponse<List<BatteryDTO>>> getAllBatteries(Authentication authentication) {
        User user = getCurrentUser(authentication);
        List<BatteryDTO> batteries = batteryService.getBatteriesByUser(user).stream()
                .map(BatteryDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(batteries));
    }

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<List<BatteryDTO>>> getBatteryStatus(Authentication authentication) {
        User user = getCurrentUser(authentication);
        List<BatteryDTO> batteries = batteryService.getBatteriesByUser(user).stream()
                .map(BatteryDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(batteries));
    }

    @GetMapping("/status/{id}")
    public ResponseEntity<ApiResponse<BatteryDTO>> getBattery(@PathVariable Long id,
                                                               Authentication authentication) {
        User user = getCurrentUser(authentication);
        return batteryService.getBattery(id, user)
                .map(battery -> ResponseEntity.ok(ApiResponse.success(BatteryDTO.fromEntity(battery))))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<BatteryDTO>> registerBattery(
            @Valid @RequestBody BatteryRegistrationRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        try {
            Battery battery = batteryService.registerBattery(user, request.getName(), request.getAddress());
            return ResponseEntity.ok(ApiResponse.success("Battery registered", BatteryDTO.fromEntity(battery)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PutMapping("/status/{id}")
    public ResponseEntity<ApiResponse<BatteryDTO>> updateBattery(@PathVariable Long id,
                                                                  @RequestBody BatteryUpdateRequest request,
                                                                  Authentication authentication) {
        User user = getCurrentUser(authentication);
        return batteryService.updateBatteryData(id, user, request.getCurrentEU(), request.getMaxEU())
                .map(battery -> ResponseEntity.ok(ApiResponse.success(BatteryDTO.fromEntity(battery))))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/status/address/{address}")
    public ResponseEntity<ApiResponse<BatteryDTO>> updateBatteryByAddress(
            @PathVariable String address,
            @RequestBody BatteryUpdateRequest request,
            Authentication authentication) {
        User user = getCurrentUser(authentication);
        return batteryService.updateBatteryDataByAddress(address, user, request.getCurrentEU(), request.getMaxEU())
                .map(battery -> ResponseEntity.ok(ApiResponse.success(BatteryDTO.fromEntity(battery))))
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/status/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBattery(@PathVariable Long id,
                                                            Authentication authentication) {
        User user = getCurrentUser(authentication);
        batteryService.deleteBattery(id, user);
        return ResponseEntity.ok(ApiResponse.success("Battery deleted", null));
    }

    /**
     * Calculate how many reactors should be active based on current battery status.
     * Returns the recommendation for the Lua client.
     */
    @GetMapping("/reactor-recommendation")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReactorRecommendation(Authentication authentication) {
        User user = getCurrentUser(authentication);

        List<Battery> batteries = batteryService.getBatteriesByUser(user);
        int totalReactors = reactorService.getReactorsByUser(user).size();

        // Calculate average charge percent across all batteries
        int avgChargePercent = batteries.isEmpty() ? 50 :
                (int) batteries.stream()
                        .mapToInt(Battery::getChargePercent)
                        .average()
                        .orElse(50);

        int activeReactors = batteryService.calculateActiveReactors(avgChargePercent, totalReactors);

        Map<String, Object> recommendation = new HashMap<>();
        recommendation.put("avgChargePercent", avgChargePercent);
        recommendation.put("totalReactors", totalReactors);
        recommendation.put("recommendedActiveReactors", activeReactors);

        return ResponseEntity.ok(ApiResponse.success(recommendation));
    }

    @GetMapping("/config")
    public ResponseEntity<ApiResponse<List<ConfigDTO>>> getConfigs() {
        List<ConfigDTO> configs = configService.getAllConfigs().stream()
                .map(ConfigDTO::fromEntity)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(configs));
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
