package com.compras.compras_api.model;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "regras_categoria")
@Getter
@Setter
public class RegraCategoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_regra")
    private Integer idRegra;

    @Column(name = "palavra_chave", nullable = false, length = 100)
    private String palavraChave;

    @Column(name = "categoria", nullable = false, length = 100)
    private String categoria;

    @Column(name = "ativo")
    private Boolean ativo = true;
}