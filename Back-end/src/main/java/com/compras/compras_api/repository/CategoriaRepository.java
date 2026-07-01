package com.compras.compras_api.repository;

import com.compras.compras_api.model.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CategoriaRepository extends JpaRepository<Categoria, Integer> {

    Optional<Categoria> findByNomeIgnoreCase(String nome);

    @Query("""
            SELECT
                c.idCategoria,
                c.nome,
                c.nomeRelatorio
            FROM Categoria c
            WHERE (:nome IS NULL OR LOWER(c.nome) LIKE LOWER(CONCAT('%', :nome, '%')))
            AND (:nomeRelatorio IS NULL OR LOWER(c.nomeRelatorio) LIKE LOWER(CONCAT('%', :nomeRelatorio, '%')))
            AND (:somenteSemGrupo = false OR c.nomeRelatorio IS NULL OR c.nomeRelatorio = '')
            ORDER BY COALESCE(c.nomeRelatorio, c.nome), c.nome
            """)
    List<Object[]> buscarCategoriasAgrupamento(
            @Param("nome") String nome,
            @Param("nomeRelatorio") String nomeRelatorio,
            @Param("somenteSemGrupo") Boolean somenteSemGrupo
    );
}