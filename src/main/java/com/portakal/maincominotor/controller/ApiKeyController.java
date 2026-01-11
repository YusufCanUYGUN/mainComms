package com.portakal.maincominotor.controller;

import com.portakal.maincominotor.dto.ApiKeyCreateRequest;
import com.portakal.maincominotor.dto.ApiKeyDTO;
import com.portakal.maincominotor.model.ApiKey;
import com.portakal.maincominotor.model.User;
import com.portakal.maincominotor.service.ApiKeyService;
import com.portakal.maincominotor.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/dashboard/api-keys")
@RequiredArgsConstructor
public class ApiKeyController {

    private final ApiKeyService apiKeyService;
    private final UserService userService;

    @GetMapping
    public String listApiKeys(Authentication authentication, Model model) {
        User user = getCurrentUser(authentication);
        List<ApiKeyDTO> apiKeys = apiKeyService.getUserApiKeys(user).stream()
                .map(ApiKeyDTO::fromEntity)
                .toList();
        model.addAttribute("apiKeys", apiKeys);
        model.addAttribute("createRequest", new ApiKeyCreateRequest());
        return "api-keys";
    }

    @PostMapping
    public String createApiKey(@Valid @ModelAttribute("createRequest") ApiKeyCreateRequest request,
                               Authentication authentication,
                               RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        ApiKey apiKey = apiKeyService.generateApiKey(user, request.getName());

        redirectAttributes.addFlashAttribute("newApiKey", apiKey.getKeyValue());
        redirectAttributes.addFlashAttribute("success", "API key created successfully. Copy it now - it won't be shown again!");

        return "redirect:/dashboard/api-keys";
    }

    @PostMapping("/{id}/revoke")
    public String revokeApiKey(@PathVariable Long id,
                               Authentication authentication,
                               RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        apiKeyService.revokeApiKey(id, user);
        redirectAttributes.addFlashAttribute("success", "API key revoked successfully.");
        return "redirect:/dashboard/api-keys";
    }

    @PostMapping("/{id}/regenerate")
    public String regenerateApiKey(@PathVariable Long id,
                                   Authentication authentication,
                                   RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        apiKeyService.regenerateApiKey(id, user)
                .ifPresent(apiKey -> {
                    redirectAttributes.addFlashAttribute("newApiKey", apiKey.getKeyValue());
                    redirectAttributes.addFlashAttribute("success", "API key regenerated. Copy it now - it won't be shown again!");
                });
        return "redirect:/dashboard/api-keys";
    }

    @PostMapping("/{id}/delete")
    public String deleteApiKey(@PathVariable Long id,
                               Authentication authentication,
                               RedirectAttributes redirectAttributes) {
        User user = getCurrentUser(authentication);
        apiKeyService.deleteApiKey(id, user);
        redirectAttributes.addFlashAttribute("success", "API key deleted successfully.");
        return "redirect:/dashboard/api-keys";
    }

    private User getCurrentUser(Authentication authentication) {
        String username = authentication.getName();
        return userService.getUserByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
