package com.portakal.maincominotor.repository;

import com.portakal.maincominotor.model.ApiKey;
import com.portakal.maincominotor.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ApiKeyRepository extends JpaRepository<ApiKey, Long> {

    Optional<ApiKey> findByKeyValue(String keyValue);

    Optional<ApiKey> findByKeyValueAndEnabledTrue(String keyValue);

    List<ApiKey> findByUser(User user);

    List<ApiKey> findByUserAndEnabledTrue(User user);
}
