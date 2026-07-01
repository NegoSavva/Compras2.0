package com.compras.compras_api.repository;

import com.compras.compras_api.model.Mercado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface MercadoRepository extends JpaRepository<Mercado, Integer> {

    Optional<Mercado> findByCnpj(String cnpj);

    Optional<Mercado> findFirstByNomeIgnoreCase(String nome);

    @Query("""
            SELECT m
            FROM Mercado m
            WHERE REPLACE(REPLACE(REPLACE(m.cnpj, '.', ''), '/', ''), '-', '') = :cnpjNumeros
            """)
    Optional<Mercado> findByCnpjSomenteNumeros(
            @Param("cnpjNumeros") String cnpjNumeros
    );
}