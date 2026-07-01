package com.compras.compras_api.repository;

import com.compras.compras_api.model.ItemCompra;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ItemCompraRepository extends JpaRepository<ItemCompra, Integer> {

    List<ItemCompra> findByCompra_IdCompra(Integer idCompra);

    void deleteByCompra_IdCompra(Integer idCompra);

    @Query("""
        SELECT
            COALESCE(p.nomeRelatorio, p.nome),
            COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria'),
            COUNT(i),
            COALESCE(SUM(i.quantidade), 0),
            COALESCE(SUM(i.valorTotal), 0)
        FROM ItemCompra i
        JOIN i.produto p
        LEFT JOIN p.categoria c
        JOIN i.compra compra
        LEFT JOIN compra.mercado m
        WHERE compra.dataCompra >= :inicio
        AND compra.dataCompra < :fim
        AND (:idMercado IS NULL OR m.idMercado = :idMercado)
        GROUP BY COALESCE(p.nomeRelatorio, p.nome),
                 COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria')
        ORDER BY COALESCE(SUM(i.quantidade), 0) DESC,
                 COALESCE(SUM(i.valorTotal), 0) DESC
        """)
List<Object[]> buscarProdutosMaisCompradosPorPeriodo(
        @Param("inicio") LocalDateTime inicio,
        @Param("fim") LocalDateTime fim,
        @Param("idMercado") Integer idMercado
);

   @Query("""
        SELECT
            COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria'),
            COUNT(i),
            COALESCE(SUM(i.quantidade), 0),
            COALESCE(SUM(i.valorTotal), 0)
        FROM ItemCompra i
        JOIN i.produto p
        LEFT JOIN p.categoria c
        JOIN i.compra compra
        LEFT JOIN compra.mercado m
        WHERE compra.dataCompra >= :inicio
        AND compra.dataCompra < :fim
        AND (:idMercado IS NULL OR m.idMercado = :idMercado)
        GROUP BY COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria')
ORDER BY COALESCE(SUM(i.valorTotal), 0) DESC
        """)
List<Object[]> buscarGastosPorCategoriaPorPeriodo(
        @Param("inicio") LocalDateTime inicio,
        @Param("fim") LocalDateTime fim,
        @Param("idMercado") Integer idMercado
);
   @Query("""
        SELECT
            compra.idCompra,
            p.nome,
            COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria'),
            COALESCE(m.nome, 'Mercado não identificado'),
            compra.dataCompra,
            i.quantidade,
            i.unidade,
            i.valorUnitario,
            i.valorTotal
        FROM ItemCompra i
        JOIN i.produto p
        LEFT JOIN p.categoria c
        JOIN i.compra compra
        LEFT JOIN compra.mercado m
        WHERE compra.dataCompra >= :inicio
        AND compra.dataCompra < :fim
        AND (:idMercado IS NULL OR m.idMercado = :idMercado)
        AND LOWER(COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria')) = LOWER(:categoria)
        ORDER BY compra.dataCompra DESC, p.nome ASC
        """)
List<Object[]> buscarDetalhesPorCategoriaPorPeriodo(
        @Param("categoria") String categoria,
        @Param("inicio") LocalDateTime inicio,
        @Param("fim") LocalDateTime fim,
        @Param("idMercado") Integer idMercado
);
@Query("""
        SELECT
            compra.idCompra,
            p.nome,
            COALESCE(m.nome, 'Mercado não identificado'),
            compra.dataCompra,
            i.quantidade,
            i.unidade,
            i.valorUnitario,
            i.valorTotal,
            i.quantidadeNormalizada,
            i.unidadeNormalizada,
            i.precoPorUnidade
        FROM ItemCompra i
        JOIN i.produto p
        JOIN i.compra compra
        LEFT JOIN compra.mercado m
        WHERE compra.dataCompra >= :inicio
        AND compra.dataCompra < :fim
        AND (:idMercado IS NULL OR m.idMercado = :idMercado)
        AND (
            LOWER(p.nome) = LOWER(:produtoNome)
            OR LOWER(COALESCE(p.nomeRelatorio, '')) = LOWER(:produtoNome)
        )
        ORDER BY compra.dataCompra ASC
        """)
List<Object[]> buscarHistoricoPrecoProdutoPorPeriodo(
        @Param("produtoNome") String produtoNome,
        @Param("inicio") LocalDateTime inicio,
        @Param("fim") LocalDateTime fim,
        @Param("idMercado") Integer idMercado
);
@Query("""
       SELECT
    compra.idCompra,
    compra.dataCompra,
    COALESCE(m.nome, 'Mercado não identificado'),
    COALESCE(c.nomeRelatorio, c.nome, 'Sem categoria'),
    COALESCE(p.nomeRelatorio, p.nome),
    i.quantidade,
    i.unidade,
    i.valorUnitario,
    i.valorTotal
        FROM ItemCompra i
        JOIN i.produto p
        LEFT JOIN p.categoria c
        JOIN i.compra compra
        LEFT JOIN compra.mercado m
        WHERE compra.dataCompra >= :inicio
        AND compra.dataCompra < :fim
        AND (:idMercado IS NULL OR m.idMercado = :idMercado)
        ORDER BY compra.dataCompra DESC, m.nome ASC, p.nome ASC
        """)
List<Object[]> buscarItensParaExportacaoCsv(
        @Param("inicio") LocalDateTime inicio,
        @Param("fim") LocalDateTime fim,
        @Param("idMercado") Integer idMercado
);
}
