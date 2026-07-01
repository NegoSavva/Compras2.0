package com.compras.compras_api.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@AllArgsConstructor
public class ItemCompraResponse {

    private Integer idItem;
    private String produtoNome;
    private String categoriaNome;
    private BigDecimal quantidade;
    private String unidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
    private BigDecimal quantidadeNormalizada;
    private String unidadeNormalizada;
    private BigDecimal precoPorUnidade;
}
