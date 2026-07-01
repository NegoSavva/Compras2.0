package com.compras.compras_api.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class CategoriaAgrupamentoResponse {

    private Integer idCategoria;
    private String nome;
    private String nomeRelatorio;
}