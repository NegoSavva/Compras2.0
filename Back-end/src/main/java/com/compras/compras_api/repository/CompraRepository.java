package com.compras.compras_api.repository;

import com.compras.compras_api.model.Compra;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface CompraRepository extends JpaRepository<Compra, Integer> {

    Optional<Compra> findByChaveAcesso(String chaveAcesso);

    boolean existsByChaveAcesso(String chaveAcesso);

    boolean existsByUrlNota(String urlNota);

    @Query("""
            SELECT COALESCE(SUM(c.valorTotal), 0)
            FROM Compra c
            LEFT JOIN c.mercado m
            WHERE c.dataCompra >= :inicio
            AND c.dataCompra < :fim
            AND (:idMercado IS NULL OR m.idMercado = :idMercado)
            """)
    BigDecimal somarValorTotalPorPeriodo(
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim,
            @Param("idMercado") Integer idMercado
    );

    @Query("""
            SELECT COUNT(c)
            FROM Compra c
            LEFT JOIN c.mercado m
            WHERE c.dataCompra >= :inicio
            AND c.dataCompra < :fim
            AND (:idMercado IS NULL OR m.idMercado = :idMercado)
            """)
    Long contarComprasPorPeriodo(
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim,
            @Param("idMercado") Integer idMercado
    );

    @Query("""
            SELECT 
                COALESCE(m.nome, 'Mercado não identificado'),
                COUNT(c),
                COALESCE(SUM(c.valorTotal), 0)
            FROM Compra c
            LEFT JOIN c.mercado m
            WHERE c.dataCompra >= :inicio
            AND c.dataCompra < :fim
            AND (:idMercado IS NULL OR m.idMercado = :idMercado)
            GROUP BY m.nome
            ORDER BY COALESCE(SUM(c.valorTotal), 0) DESC
            """)
    List<Object[]> buscarComprasPorMercadoPorPeriodo(
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim,
            @Param("idMercado") Integer idMercado
    );
    @Query("""
        SELECT c
        FROM Compra c
        LEFT JOIN c.mercado m
        WHERE (:idMercado IS NULL OR m.idMercado = :idMercado)
        AND (:dataInicio IS NULL OR c.dataCompra >= :dataInicio)
        AND (:dataFim IS NULL OR c.dataCompra < :dataFim)
        AND (:valorMinimo IS NULL OR c.valorTotal >= :valorMinimo)
        AND (:valorMaximo IS NULL OR c.valorTotal <= :valorMaximo)
        AND (
            :formaPagamento IS NULL
            OR LOWER(c.formaPagamento) LIKE LOWER(CONCAT('%', :formaPagamento, '%'))
        )
        ORDER BY c.dataCompra DESC
        """)
List<Compra> buscarComprasComFiltros(
        @Param("idMercado") Integer idMercado,
        @Param("dataInicio") LocalDateTime dataInicio,
        @Param("dataFim") LocalDateTime dataFim,
        @Param("valorMinimo") BigDecimal valorMinimo,
        @Param("valorMaximo") BigDecimal valorMaximo,
        @Param("formaPagamento") String formaPagamento
);
    @Query("""
        SELECT 
            FUNCTION('MONTH', c.dataCompra),
            COUNT(c),
            COALESCE(SUM(c.valorTotal), 0)
        FROM Compra c
        LEFT JOIN c.mercado m
        WHERE c.dataCompra >= :inicio
        AND c.dataCompra < :fim
        AND (:idMercado IS NULL OR m.idMercado = :idMercado)
        GROUP BY FUNCTION('MONTH', c.dataCompra)
        ORDER BY FUNCTION('MONTH', c.dataCompra)
        """)
List<Object[]> buscarHistoricoGastosMensais(
        @Param("inicio") LocalDateTime inicio,
        @Param("fim") LocalDateTime fim,
        @Param("idMercado") Integer idMercado
);
}