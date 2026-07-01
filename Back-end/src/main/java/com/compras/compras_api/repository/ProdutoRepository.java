package com.compras.compras_api.repository;

import com.compras.compras_api.model.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ProdutoRepository extends JpaRepository<Produto, Integer> {

    Optional<Produto> findFirstByNomeIgnoreCase(String nome);

    @Query("""
            SELECT
                p.idProduto,
                p.nome,
                COALESCE(c.nome, 'Sem categoria'),
                r.idRegra,
                r.palavraChave,
                r.categoria
            FROM Produto p
            LEFT JOIN p.categoria c
            LEFT JOIN RegraCategoria r
                ON r.ativo = true
                AND LOWER(p.nome) LIKE LOWER(CONCAT('%', r.palavraChave, '%'))
            WHERE (:nome IS NULL OR LOWER(p.nome) LIKE LOWER(CONCAT('%', :nome, '%')))
            AND (:categoria IS NULL OR LOWER(COALESCE(c.nome, 'Sem categoria')) = LOWER(:categoria))
            ORDER BY COALESCE(c.nome, 'Sem categoria') ASC, p.nome ASC, r.palavraChave ASC
            """)
    List<Object[]> buscarProdutosClassificados(
            @Param("nome") String nome,
            @Param("categoria") String categoria
    );
    @Query("""
        SELECT
            p.idProduto,
            p.nome,
            p.nomeRelatorio,
            COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria')
        FROM Produto p
        LEFT JOIN p.categoria c
        WHERE (:nome IS NULL OR LOWER(p.nome) LIKE LOWER(CONCAT('%', :nome, '%')))
        AND (:nomeRelatorio IS NULL OR LOWER(p.nomeRelatorio) LIKE LOWER(CONCAT('%', :nomeRelatorio, '%')))
        AND (:categoria IS NULL OR LOWER(COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria')) = LOWER(:categoria))
        AND (:somenteSemGrupo = false OR p.nomeRelatorio IS NULL OR p.nomeRelatorio = '')
        ORDER BY CASE
                    WHEN p.nomeRelatorio IS NULL OR p.nomeRelatorio = '' THEN 1
                    ELSE 0
                 END,
                 COALESCE(p.nomeRelatorio, p.nome),
                 p.nome
        """)
List<Object[]> buscarProdutosAgrupamento(
        @Param("nome") String nome,
        @Param("nomeRelatorio") String nomeRelatorio,
        @Param("categoria") String categoria,
        @Param("somenteSemGrupo") Boolean somenteSemGrupo
);
}