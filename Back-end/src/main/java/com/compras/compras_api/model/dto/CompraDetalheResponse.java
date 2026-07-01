package com.compras.compras_api.model.dto;


import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
public class CompraDetalheResponse {

    private Integer idCompra;

    private String mercadoNome;
    private String mercadoCnpj;
    private String mercadoEndereco;

    private String chaveAcesso;
    private String urlNota;
    private LocalDateTime dataCompra;
    private BigDecimal valorTotal;
    private String formaPagamento;
    private String statusProcessamento;
    private LocalDateTime criadoEm;

    private List<ItemCompraResponse> itens = new ArrayList<>();
}
