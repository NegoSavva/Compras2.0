package com.compras.compras_api.model.dto;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@AllArgsConstructor
public class ProdutoMaisCompradoResponse {

    private String produtoNome;
    private String categoriaNome;
    private Long frequenciaCompra;
    private BigDecimal quantidadeTotal;
    private BigDecimal totalGasto;
}
