package com.compras.compras_api.model.service;



import com.compras.compras_api.model.dto.NotaLeituraResponse;
import org.springframework.stereotype.Service;
import com.compras.compras_api.repository.CompraRepository;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import com.compras.compras_api.model.Mercado;
import com.compras.compras_api.repository.MercadoRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class NotaLeituraService {

    private final MercadoRepository mercadoRepository;
    private final CompraRepository compraRepository;
    private final NfceExtractorService nfceExtractorService;

   public NotaLeituraResponse lerNota(String url) {
    String urlNormalizada = normalizarUrl(url);

    validarUrl(urlNormalizada);

    String chaveAcesso = extrairChaveAcesso(urlNormalizada);

    if (chaveAcesso != null && compraRepository.existsByChaveAcesso(chaveAcesso)) {
        throw new IllegalArgumentException("Nota já cadastrada. Esta chave de acesso já existe no sistema.");
    }

    if (compraRepository.existsByUrlNota(urlNormalizada)) {
        throw new IllegalArgumentException("Nota já cadastrada. Esta URL já existe no sistema.");
    }

    NotaLeituraResponse response = nfceExtractorService.extrair(urlNormalizada);

    aplicarNomeAmigavelDoMercado(response);

    return response;
}

private void aplicarNomeAmigavelDoMercado(NotaLeituraResponse response) {
    if (response == null || response.getMercadoCnpj() == null) {
        return;
    }

    String cnpjNumeros = somenteNumeros(response.getMercadoCnpj());

    if (cnpjNumeros == null) {
        return;
    }

    mercadoRepository.findByCnpjSomenteNumeros(cnpjNumeros)
            .ifPresent(mercado -> aplicarDadosMercadoExistente(response, mercado));
}

private void aplicarDadosMercadoExistente(
        NotaLeituraResponse response,
        Mercado mercado
) {
    if (mercado.getNome() != null && !mercado.getNome().isBlank()) {
        response.setMercadoNome(mercado.getNome());
    }

    if (
            (response.getMercadoEndereco() == null || response.getMercadoEndereco().isBlank())
                    && mercado.getEndereco() != null
                    && !mercado.getEndereco().isBlank()
    ) {
        response.setMercadoEndereco(mercado.getEndereco());
    }
}

private String somenteNumeros(String texto) {
    if (texto == null) {
        return null;
    }

    String numeros = texto.replaceAll("\\D", "");

    return numeros.isBlank() ? null : numeros;
}
    private void validarUrl(String url) {
        if (url == null || url.isEmpty()) {
            throw new IllegalArgumentException("URL não pode ser nula ou vazia.");
        }
    }

    private String normalizarUrl(String url) {
    if (url == null) {
        return null;
    }

    return url
            .trim()
            .replace("|", "%7C");
    }

    private String extrairChaveAcesso(String url) {
        if (url == null || url.isEmpty()) {
            return null;
        }
        
        Pattern pattern = Pattern.compile("chave_acesso=([^&]+)");
        Matcher matcher = pattern.matcher(url);
        
        if (matcher.find()) {
            return matcher.group(1);
        }
        
        return null;
    }
}