package com.compras.compras_api.model.dto;



import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NotaLeituraRequest {

    @NotBlank(message = "A URL da NFC-e é obrigatória.")
    private String url;
}
