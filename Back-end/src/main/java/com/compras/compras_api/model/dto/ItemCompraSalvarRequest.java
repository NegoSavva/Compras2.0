package com.compras.compras_api.model.dto;


import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class ItemCompraSalvarRequest {

    private String nome;
    private BigDecimal quantidade;
    private String unidade;
    private BigDecimal valorUnitario;
    private BigDecimal valorTotal;
    private String categoria;
}