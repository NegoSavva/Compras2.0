package com.compras.compras_api.model.dto;


import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegraCategoriaRequest {

    @NotBlank(message = "A palavra-chave é obrigatória.")
    private String palavraChave;

    @NotBlank(message = "A categoria é obrigatória.")
    private String categoria;
}