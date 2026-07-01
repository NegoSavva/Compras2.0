package com.compras.compras_api.model.dto;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class RegraCategoriaResponse {

    private Integer idRegra;
    private String palavraChave;
    private String categoria;
    private Boolean ativo;
}