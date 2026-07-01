package com.compras.compras_api.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
public class DetalheCategoriaResponse {

    private Integer idCompra;
    private String produtoNome;
    private String categoriaNome;
    private String mercadoNome;
    private LocalDateTime dataCompra;
    private BigDecimal quantidade;
    private String unidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
}