package com.compras.compras_api.model.dto;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@AllArgsConstructor
public class ComprasPorMercadoResponse {

    private String mercadoNome;
    private Long quantidadeCompras;
    private BigDecimal totalGasto;
}