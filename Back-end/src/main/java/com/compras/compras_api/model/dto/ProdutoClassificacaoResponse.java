package com.compras.compras_api.model.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class ProdutoClassificacaoResponse {

    private Integer idProduto;
    private String nome;
    private String categoria;
    private Integer idRegra;
    private String palavraChaveRegra;
    private String categoriaRegra;
}