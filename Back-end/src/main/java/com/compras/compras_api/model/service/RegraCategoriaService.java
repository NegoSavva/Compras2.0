package com.compras.compras_api.model.service;


import com.compras.compras_api.model.dto.RegraCategoriaRequest;
import com.compras.compras_api.model.dto.RegraCategoriaResponse;
import com.compras.compras_api.model.RegraCategoria;
import com.compras.compras_api.repository.RegraCategoriaRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RegraCategoriaService {

    private final RegraCategoriaRepository regraCategoriaRepository;

    public List<RegraCategoriaResponse> listarRegras() {
        return regraCategoriaRepository.findAllByOrderByPalavraChaveAsc()
                .stream()
                .map(this::converterParaResponse)
                .toList();
    }

    @Transactional
    public RegraCategoriaResponse criarRegra(RegraCategoriaRequest request) {
        String palavraChave = limparTexto(request.getPalavraChave());
        String categoria = limparTexto(request.getCategoria());

        validarDados(palavraChave, categoria);

        regraCategoriaRepository.findByPalavraChaveIgnoreCaseAndAtivoTrue(palavraChave)
                .ifPresent(regra -> {
                    throw new IllegalArgumentException("Já existe uma regra ativa com essa palavra-chave.");
                });

        RegraCategoria regra = new RegraCategoria();
        regra.setPalavraChave(palavraChave);
        regra.setCategoria(categoria);
        regra.setAtivo(true);

        RegraCategoria salva = regraCategoriaRepository.save(regra);

        return converterParaResponse(salva);
    }

    @Transactional
    public RegraCategoriaResponse atualizarRegra(Integer idRegra, RegraCategoriaRequest request) {
        RegraCategoria regra = regraCategoriaRepository.findById(idRegra)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Regra de categoria não encontrada."
                ));

        String palavraChave = limparTexto(request.getPalavraChave());
        String categoria = limparTexto(request.getCategoria());

        validarDados(palavraChave, categoria);

        regra.setPalavraChave(palavraChave);
        regra.setCategoria(categoria);
        regra.setAtivo(true);

        RegraCategoria atualizada = regraCategoriaRepository.save(regra);

        return converterParaResponse(atualizada);
    }

    @Transactional
    public void desativarRegra(Integer idRegra) {
        RegraCategoria regra = regraCategoriaRepository.findById(idRegra)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Regra de categoria não encontrada."
                ));

        regra.setAtivo(false);
        regraCategoriaRepository.save(regra);
    }

    private void validarDados(String palavraChave, String categoria) {
        if (palavraChave == null || palavraChave.isBlank()) {
            throw new IllegalArgumentException("A palavra-chave é obrigatória.");
        }

        if (categoria == null || categoria.isBlank()) {
            throw new IllegalArgumentException("A categoria é obrigatória.");
        }

        if (palavraChave.length() < 2) {
            throw new IllegalArgumentException("A palavra-chave deve ter pelo menos 2 caracteres.");
        }
    }

    private RegraCategoriaResponse converterParaResponse(RegraCategoria regra) {
        return new RegraCategoriaResponse(
                regra.getIdRegra(),
                regra.getPalavraChave(),
                regra.getCategoria(),
                regra.getAtivo()
        );
    }

    private String limparTexto(String texto) {
        if (texto == null || texto.isBlank()) {
            return null;
        }

        return texto.trim();
    }
}
