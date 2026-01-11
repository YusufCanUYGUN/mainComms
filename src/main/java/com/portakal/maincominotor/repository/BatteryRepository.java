package com.portakal.maincominotor.repository;

import com.portakal.maincominotor.model.Battery;
import com.portakal.maincominotor.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface BatteryRepository extends JpaRepository<Battery, Long> {

    List<Battery> findByUser(User user);

    Optional<Battery> findByIdAndUser(Long id, User user);

    Optional<Battery> findByAddressAndUser(String address, User user);

    boolean existsByAddressAndUser(String address, User user);
}
