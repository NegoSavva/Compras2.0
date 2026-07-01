package com.compras.compras_api.model.dto;


import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class MercadoResponse {

    private Integer idMercado;
    private String nome;
    private String cnpj;
    private String endereco;
}
