package com.compras.compras_api.model.dto;


import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
public class CompraSalvarRequest {

    private String mercadoNome;
    private String mercadoCnpj;
    private String mercadoEndereco;

    private String chaveAcesso;

    @NotBlank(message = "A URL da nota é obrigatória.")
    private String urlNota;

    private LocalDateTime dataCompra;
    private BigDecimal valorTotal;
    private String formaPagamento;
    private String statusProcessamento;

    private List<ItemCompraSalvarRequest> itens = new ArrayList<>();
}