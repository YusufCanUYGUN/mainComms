package com.portakal.maincominotor.controller;

import com.portakal.maincominotor.dto.BatteryDTO;
import com.portakal.maincominotor.dto.ReactorDTO;
import com.portakal.maincominotor.model.ControlMode;
import com.portakal.maincominotor.model.ReactorStatus;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.service.ApiKeyService;
import com.portakal.maincominotor.service.BatteryService;
import com.portakal.maincominotor.service.ReactorService;
import com.portakal.maincominotor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final ReactorService reactorService;
    private final BatteryService batteryService;
    private final UserService userService;
    private final ApiKeyService apiKeyService;

    @GetMapping
    public String dashboard(Authentication authentication, Model model) {
        User user = getCurrentUser(authentication);

        List<ReactorDTO> reactors = reactorService.getReactorsByUser(user).stream()
                .map(ReactorDTO::fromEntity)
                .toList();
        List<BatteryDTO> batteries = batteryService.getBatteriesByUser(user).stream()
                .map(BatteryDTO::fromEntity)
                .toList();

        // Calculate stats for gauges
        long totalEuOutput = reactors.stream()
                .filter(r -> r.getStatus() == ReactorStatus.ONLINE)
                .mapToLong(ReactorDTO::getEuOutput)
                .sum();

        long maxEuOutput = reactors.size() * 500L; // Assume max 500 EU/t per reactor

        int avgBatteryPercent = batteries.isEmpty() ? 0 :
                (int) batteries.stream()
                        .mapToInt(BatteryDTO::getChargePercent)
                        .average()
                        .orElse(0);

        long onlineReactors = reactors.stream()
                .filter(r -> r.getStatus() == ReactorStatus.ONLINE)
                .count();

        long enabledReactors = reactors.stream()
                .filter(ReactorDTO::isEnabled)
                .count();

        int apiKeyCount = apiKeyService.getUserApiKeys(user).size();

        model.addAttribute("reactors", reactors);
        model.addAttribute("batteries", batteries);
        model.addAttribute("username", user.getUsername());
        model.addAttribute("totalEuOutput", totalEuOutput);
        model.addAttribute("maxEuOutput", maxEuOutput);
        model.addAttribute("avgBatteryPercent", avgBatteryPercent);
        model.addAttribute("onlineReactors", onlineReactors);
        model.addAttribute("enabledReactors", enabledReactors);
        model.addAttribute("apiKeyCount", apiKeyCount);
        model.addAttribute("controlModes", ControlMode.values());

        return "dashboard";
    }

    @GetMapping("/reactors")
    public String reactorsPage(Authentication authentication, Model model,
                               @RequestParam(required = false) Long selected) {
        User user = getCurrentUser(authentication);

        List<ReactorDTO> reactors = reactorService.getReactorsByUser(user).stream()
                .map(ReactorDTO::fromEntity)
                .toList();

        model.addAttribute("reactors", reactors);
        model.addAttribute("username", user.getUsername());
        model.addAttribute("controlModes", ControlMode.values());

        // If a reactor is selected, add its details
        if (selected != null) {
            reactors.stream()
                    .filter(r -> r.getId().equals(selected))
                    .findFirst()
                    .ifPresent(reactor -> model.addAttribute("selectedReactor", reactor));
        } else if (!reactors.isEmpty()) {
            // Default to first reactor
            model.addAttribute("selectedReactor", reactors.get(0));
        }

        return "reactors";
    }

    @GetMapping("/reactors/{id}")
    public String reactorDetail(@PathVariable Long id, Authentication authentication, Model model) {
        User user = getCurrentUser(authentication);

        return reactorService.getReactor(id, user)
                .map(reactor -> {
                    model.addAttribute("reactor", ReactorDTO.fromEntity(reactor));
                    model.addAttribute("controlModes", ControlMode.values());
                    return "reactor-detail";
                })
                .orElse("redirect:/dashboard/reactors");
    }

    @PostMapping("/reactors/{id}/control-mode")
    public String setControlMode(@PathVariable Long id,
                                 @RequestParam ControlMode mode,
                                 Authentication authentication,
                                 @RequestParam(required = false) String redirect,
                                 RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        reactorService.setControlMode(id, user, mode);
        redirectAttributes.addFlashAttribute("success", "Control mode set to " + mode + ".");

        if ("dashboard".equals(redirect)) {
            return "redirect:/dashboard";
        }
        return "redirect:/dashboard/reactors?selected=" + id;
    }

    @PostMapping("/reactors/{id}/disable")
    public String disableReactor(@PathVariable Long id,
                                 Authentication authentication,
                                 @RequestParam(required = false) String redirect,
                                 RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        reactorService.setControlMode(id, user, ControlMode.DISABLED);
        redirectAttributes.addFlashAttribute("success", "Reactor disabled.");

        if ("dashboard".equals(redirect)) {
            return "redirect:/dashboard";
        }
        return "redirect:/dashboard/reactors?selected=" + id;
    }

    @PostMapping("/reactors/{id}/auto")
    public String setAutoMode(@PathVariable Long id,
                              Authentication authentication,
                              @RequestParam(required = false) String redirect,
                              RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        reactorService.setControlMode(id, user, ControlMode.AUTO);
        redirectAttributes.addFlashAttribute("success", "Reactor set to auto mode.");

        if ("dashboard".equals(redirect)) {
            return "redirect:/dashboard";
        }
        return "redirect:/dashboard/reactors?selected=" + id;
    }

    @PostMapping("/reactors/{id}/force-active")
    public String setForceActiveMode(@PathVariable Long id,
                                     Authentication authentication,
                                     @RequestParam(required = false) String redirect,
                                     RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        reactorService.setControlMode(id, user, ControlMode.FORCE_ACTIVE);
        redirectAttributes.addFlashAttribute("success", "Reactor set to force active mode.");

        if ("dashboard".equals(redirect)) {
            return "redirect:/dashboard";
        }
        return "redirect:/dashboard/reactors?selected=" + id;
    }

    @GetMapping("/battery")
    public String batteryPage(Authentication authentication, Model model,
                              @RequestParam(required = false) Long selected) {
        User user = getCurrentUser(authentication);

        List<BatteryDTO> batteries = batteryService.getBatteriesByUser(user).stream()
                .map(BatteryDTO::fromEntity)
                .toList();

        model.addAttribute("batteries", batteries);
        model.addAttribute("username", user.getUsername());

        // If a battery is selected, add its details
        if (selected != null) {
            batteries.stream()
                    .filter(b -> b.getId().equals(selected))
                    .findFirst()
                    .ifPresent(battery -> model.addAttribute("selectedBattery", battery));
        } else if (!batteries.isEmpty()) {
            // Default to first battery
            model.addAttribute("selectedBattery", batteries.get(0));
        }

        return "battery";
    }

    private User getCurrentUser(Authentication authentication) {
        String username = authentication.getName();
        return userService.getUserByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}