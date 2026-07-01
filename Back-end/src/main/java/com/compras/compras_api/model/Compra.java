package com.compras.compras_api.model;



import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "compras")
@Getter
@Setter
public class Compra {

    
    
        

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_compra")
    private Integer idCompra;

    @ManyToOne
    @JoinColumn(name = "id_mercado")
    private Mercado mercado;

    @Column(name = "chave_acesso", unique = true, length = 60)
    private String chaveAcesso;

    @Column(name = "url_nota", nullable = false, columnDefinition = "TEXT")
    private String urlNota;

    @Column(name = "data_compra")
    private LocalDateTime dataCompra;

    @Column(name = "valor_total", precision = 10, scale = 2)
    private BigDecimal valorTotal;

    @Column(name = "forma_pagamento", length = 50)
    private String formaPagamento;

    @Column(name = "status_processamento", length = 30)
    private String statusProcessamento = "PROCESSADO";

    @Column(name = "criado_em", insertable = false, updatable = false)
    private LocalDateTime criadoEm;

    
}


