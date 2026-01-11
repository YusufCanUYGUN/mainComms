package com.portakal.maincominotor.service;

import com.portakal.maincominotor.model.Battery;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.repository.BatteryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class BatteryService {

    private final BatteryRepository batteryRepository;

    public List<Battery> getBatteriesByUser(User user) {
        return batteryRepository.findByUser(user);
    }

    public Optional<Battery> getBattery(Long id, User user) {
        return batteryRepository.findByIdAndUser(id, user);
    }

    public Optional<Battery> getBatteryByAddress(String address, User user) {
        return batteryRepository.findByAddressAndUser(address, user);
    }

    @Transactional
    public Battery registerBattery(User user, String name, String address) {
        if (batteryRepository.existsByAddressAndUser(address, user)) {
            throw new IllegalArgumentException("Battery with this address already exists");
        }

        Battery battery = new Battery();
        battery.setUser(user);
        battery.setName(name);
        battery.setAddress(address);

        return batteryRepository.save(battery);
    }

    @Transactional
    public Optional<Battery> updateBatteryData(Long id, User user, long currentEU, long maxEU) {
        return batteryRepository.findByIdAndUser(id, user)
                .map(battery -> {
                    battery.setCurrentEU(currentEU);
                    battery.setMaxEU(maxEU);
                    battery.setChargePercent(maxEU > 0 ? (int) (currentEU * 100 / maxEU) : 0);
                    battery.setLastUpdated(LocalDateTime.now());
                    return batteryRepository.save(battery);
                });
    }

    @Transactional
    public Optional<Battery> updateBatteryDataByAddress(String address, User user, long currentEU, long maxEU) {
        return batteryRepository.findByAddressAndUser(address, user)
                .map(battery -> {
                    battery.setCurrentEU(currentEU);
                    battery.setMaxEU(maxEU);
                    battery.setChargePercent(maxEU > 0 ? (int) (currentEU * 100 / maxEU) : 0);
                    battery.setLastUpdated(LocalDateTime.now());
                    return batteryRepository.save(battery);
                });
    }

    @Transactional
    public void deleteBattery(Long id, User user) {
        batteryRepository.findByIdAndUser(id, user)
                .ifPresent(batteryRepository::delete);
    }

    /**
     * Calculate how many reactors should be active based on battery charge percentage.
     * < 20%: all reactors ON
     * 20-90%: gradual proportional shutdown
     * > 90%: all reactors OFF
     */
    public int calculateActiveReactors(int chargePercent, int totalReactors) {
        if (chargePercent < 20) {
            return totalReactors;
        } else if (chargePercent > 90) {
            return 0;
        } else {
            // Linear scale from 20% to 90%
            // At 20%: all reactors (totalReactors)
            // At 90%: no reactors (0)
            return (int) Math.ceil(totalReactors * (90.0 - chargePercent) / 70.0);
        }
    }
}
