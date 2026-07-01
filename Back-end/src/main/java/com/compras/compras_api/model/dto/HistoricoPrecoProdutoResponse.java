package com.compras.compras_api.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
public class HistoricoPrecoProdutoResponse {

    private Integer idCompra;
    private String produtoNome;
    private String mercadoNome;
    private LocalDateTime dataCompra;
    private BigDecimal quantidade;
    private String unidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
    private BigDecimal quantidadeNormalizada;
    private String unidadeNormalizada;
    private BigDecimal precoPorUnidade;
}
