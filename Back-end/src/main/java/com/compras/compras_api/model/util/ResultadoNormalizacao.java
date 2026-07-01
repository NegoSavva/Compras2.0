package com.compras.compras_api.model.util;

import java.math.BigDecimal;

public class ResultadoNormalizacao {

    private BigDecimal quantidade;
    private String unidade;

    public ResultadoNormalizacao(
            BigDecimal quantidade,
            String unidade
    ) {
        this.quantidade = quantidade;
        this.unidade = unidade;
    }

    public BigDecimal getQuantidade() {
        return quantidade;
    }

    public String getUnidade() {
        return unidade;
    }
}