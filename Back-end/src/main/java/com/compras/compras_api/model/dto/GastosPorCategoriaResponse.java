package com.compras.compras_api.model.dto;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@AllArgsConstructor
public class GastosPorCategoriaResponse {

    private String categoriaNome;
    private Long quantidadeItens;
    private BigDecimal quantidadeTotalProdutos;
    private BigDecimal totalGasto;
}
