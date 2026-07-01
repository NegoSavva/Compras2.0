package com.compras.compras_api.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
public class CompraResumoResponse {

    private Integer idCompra;
    private String mercadoNome;
    private LocalDateTime dataCompra;
    private BigDecimal valorTotal;
    private String formaPagamento;
    private String statusProcessamento;
    private LocalDateTime criadoEm;
    private List<String> nomesProdutos;
    private Integer quantidadeItens;
}
