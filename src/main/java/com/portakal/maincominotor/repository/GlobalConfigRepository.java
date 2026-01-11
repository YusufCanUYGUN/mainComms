package com.portakal.maincominotor.repository;

import com.portakal.maincominotor.model.GlobalConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface GlobalConfigRepository extends JpaRepository<GlobalConfig, String> {
}
