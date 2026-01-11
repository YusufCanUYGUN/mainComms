package com.portakal.maincominotor.repository;

import com.portakal.maincominotor.model.Reactor;
import com.portakal.maincominotor.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReactorRepository extends JpaRepository<Reactor, Long> {

    List<Reactor> findByUser(User user);

    Optional<Reactor> findByIdAndUser(Long id, User user);

    Optional<Reactor> findByAddressAndUser(String address, User user);

    boolean existsByAddressAndUser(String address, User user);
}
