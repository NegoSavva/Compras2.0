package com.compras.compras_api.model.dto;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@AllArgsConstructor
public class GastoMensalResponse {

    private Integer ano;
    private Integer mes;
    private String periodo;
    private BigDecimal totalGasto;
    private Long quantidadeCompras;
}