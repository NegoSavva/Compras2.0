package com.compras.compras_api.model.service;


import com.compras.compras_api.model.dto.CompraSalvaResponse;
import com.compras.compras_api.model.dto.CompraSalvarRequest;
import com.compras.compras_api.model.dto.ItemCompraSalvarRequest;
import com.compras.compras_api.model.util.ResultadoNormalizacao;
import com.compras.compras_api.model.util.UnidadeNormalizer;
import com.compras.compras_api.model.*;
import com.compras.compras_api.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.compras.compras_api.model.dto.CompraDetalheResponse;
import com.compras.compras_api.model.dto.CompraResumoResponse;
import com.compras.compras_api.model.dto.ItemCompraResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CompraService {

    private final MercadoRepository mercadoRepository;
    private final CompraRepository compraRepository;
    private final CategoriaRepository categoriaRepository;
    private final ProdutoRepository produtoRepository;
    private final ItemCompraRepository itemCompraRepository;

    @Transactional
    public CompraSalvaResponse salvarCompra(CompraSalvarRequest request) {
        validarDuplicidade(request);

        Mercado mercado = obterOuCriarMercado(request);

        
        Compra compra = new Compra();
        compra.setMercado(mercado);
        compra.setChaveAcesso(limparTexto(request.getChaveAcesso()));
        compra.setUrlNota(request.getUrlNota());
        compra.setDataCompra(request.getDataCompra());
        compra.setValorTotal(request.getValorTotal());
        compra.setFormaPagamento(request.getFormaPagamento());

        
        if (request.getStatusProcessamento() == null || request.getStatusProcessamento().isBlank()) {
            compra.setStatusProcessamento("PROCESSADO");
        } else {
            compra.setStatusProcessamento(request.getStatusProcessamento());
        }

        Compra compraSalva = compraRepository.save(compra);

        for (ItemCompraSalvarRequest itemRequest : request.getItens()) {
            salvarItemCompra(compraSalva, itemRequest);
        }

        return new CompraSalvaResponse(
                compraSalva.getIdCompra(),
                "Compra salva com sucesso."
        );
    }
public List<CompraResumoResponse> listarCompras(
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim,
        BigDecimal valorMinimo,
        BigDecimal valorMaximo,
        String formaPagamento
) {
    LocalDateTime inicio = dataInicio != null
            ? dataInicio.atStartOfDay()
            : null;

    LocalDateTime fim = dataFim != null
            ? dataFim.plusDays(1).atStartOfDay()
            : null;

    String formaPagamentoFiltro = limparTexto(formaPagamento);

    return compraRepository.buscarComprasComFiltros(
                    idMercado,
                    inicio,
                    fim,
                    valorMinimo,
                    valorMaximo,
                    formaPagamentoFiltro
            )
            .stream()
            .map(this::converterParaResumo)
            .toList();
}

public CompraDetalheResponse buscarCompraPorId(Integer idCompra) {
    Compra compra = compraRepository.findById(idCompra)
            .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Compra não encontrada."
            ));

    List<ItemCompra> itens = itemCompraRepository.findByCompra_IdCompra(idCompra);

    CompraDetalheResponse response = new CompraDetalheResponse();

    response.setIdCompra(compra.getIdCompra());

    if (compra.getMercado() != null) {
        response.setMercadoNome(compra.getMercado().getNome());
        response.setMercadoCnpj(compra.getMercado().getCnpj());
        response.setMercadoEndereco(compra.getMercado().getEndereco());
    }

    response.setChaveAcesso(compra.getChaveAcesso());
    response.setUrlNota(compra.getUrlNota());
    response.setDataCompra(compra.getDataCompra());
    response.setValorTotal(compra.getValorTotal());
    response.setFormaPagamento(compra.getFormaPagamento());
    response.setStatusProcessamento(compra.getStatusProcessamento());
    response.setCriadoEm(compra.getCriadoEm());

    List<ItemCompraResponse> itensResponse = itens.stream()
            .map(this::converterItemParaResponse)
            .toList();

    response.setItens(itensResponse);

    return response;
}

private CompraResumoResponse converterParaResumo(Compra compra) {
    String nomeMercado = compra.getMercado() != null
            ? compra.getMercado().getNome()
            : "Mercado não identificado";

    List<ItemCompra> itens = itemCompraRepository.findByCompra_IdCompra(compra.getIdCompra());

    List<String> nomesProdutos = itens.stream()
            .map(item -> item.getProduto() != null
                    ? item.getProduto().getNome()
                    : "Produto não identificado")
            .toList();

    return new CompraResumoResponse(
            compra.getIdCompra(),
            nomeMercado,
            compra.getDataCompra(),
            compra.getValorTotal(),
            compra.getFormaPagamento(),
            compra.getStatusProcessamento(),
            compra.getCriadoEm(),
            nomesProdutos,
            nomesProdutos.size()
    );
}

private ItemCompraResponse converterItemParaResponse(ItemCompra item) {
    String nomeProduto = "Produto não identificado";
    String nomeCategoria = "Sem categoria";

    if (item.getProduto() != null) {
        nomeProduto = item.getProduto().getNome();

        if (item.getProduto().getCategoria() != null) {
            nomeCategoria = item.getProduto().getCategoria().getNome();
        }
    }

    ResultadoNormalizacao normalizacao = UnidadeNormalizer.normalizar(
            item.getQuantidade(),
            item.getUnidade(),
            nomeProduto,
            item.getValorUnitario(),
            item.getValorTotal()
    );

    // Recalcula na resposta para corrigir compras antigas que podem ter sido
    // salvas antes da regra de prioridade pela medida no nome do produto.
    BigDecimal quantidadeNormalizada = normalizacao.getQuantidade();

    String unidadeNormalizada = normalizacao.getUnidade();

    BigDecimal precoPorUnidade = null;

    if (quantidadeNormalizada != null
            && quantidadeNormalizada.compareTo(BigDecimal.ZERO) > 0
            && item.getValorTotal() != null) {
        precoPorUnidade = item.getValorTotal().divide(
                quantidadeNormalizada,
                4,
                java.math.RoundingMode.HALF_UP
        );
    }

    return new ItemCompraResponse(
            item.getIdItem(),
            nomeProduto,
            nomeCategoria,
            item.getQuantidade(),
            item.getUnidade(),
            item.getValorUnitario(),
            item.getValorTotal(),
            quantidadeNormalizada,
            unidadeNormalizada,
            precoPorUnidade
    );
}
    private void validarDuplicidade(CompraSalvarRequest request) {
        String chaveAcesso = limparTexto(request.getChaveAcesso());

        if (chaveAcesso != null && compraRepository.existsByChaveAcesso(chaveAcesso)) {
            throw new IllegalArgumentException("Nota já cadastrada. Esta chave de acesso já existe no sistema.");
        }

        if (compraRepository.existsByUrlNota(request.getUrlNota())) {
            throw new IllegalArgumentException("Nota já cadastrada. Esta URL já existe no sistema.");
        }
    }

   private Mercado obterOuCriarMercado(CompraSalvarRequest request) {
    String nome = limparTexto(request.getMercadoNome());
    String cnpj = limparTexto(request.getMercadoCnpj());
    String endereco = limparTexto(request.getMercadoEndereco());

    if (nome == null) {
        nome = "Mercado não identificado";
    }

    if (cnpj != null) {
        String cnpjNumeros = somenteNumeros(cnpj);
        String nomeFinal = nome;
        String cnpjFinal = cnpj;
        String enderecoFinal = endereco;

        if (cnpjNumeros != null) {
            return mercadoRepository.findByCnpjSomenteNumeros(cnpjNumeros)
                    .map(mercadoExistente -> atualizarMercado(
                            mercadoExistente,
                            nomeFinal,
                            cnpjFinal,
                            enderecoFinal
                    ))
                    .orElseGet(() -> criarMercado(nomeFinal, cnpjFinal, enderecoFinal));
        }

        return mercadoRepository.findByCnpj(cnpj)
                .map(mercadoExistente -> atualizarMercado(
                        mercadoExistente,
                        nomeFinal,
                        cnpjFinal,
                        enderecoFinal
                ))
                .orElseGet(() -> criarMercado(nomeFinal, cnpjFinal, enderecoFinal));
    }

    String nomeFinal = nome;
    String enderecoFinal = endereco;

    return mercadoRepository.findFirstByNomeIgnoreCase(nomeFinal)
            .map(mercadoExistente -> atualizarMercado(
                    mercadoExistente,
                    nomeFinal,
                    null,
                    enderecoFinal
            ))
            .orElseGet(() -> criarMercado(nomeFinal, null, enderecoFinal));
}
private Mercado atualizarMercado(
        Mercado mercado,
        String nome,
        String cnpj,
        String endereco
) {
    boolean alterou = false;

    if (deveAtualizarNomeMercado(mercado.getNome(), nome)) {
        mercado.setNome(nome);
        alterou = true;
    }

    if (cnpj != null && !cnpj.isBlank()) {
        mercado.setCnpj(cnpj);
        alterou = true;
    }

    if (endereco != null && !endereco.isBlank()) {
        mercado.setEndereco(endereco);
        alterou = true;
    }

    if (alterou) {
        return mercadoRepository.save(mercado);
    }

    return mercado;
}
private boolean deveAtualizarNomeMercado(String nomeAtual, String nomeNovo) {
    nomeNovo = limparTexto(nomeNovo);

    if (nomeNovo == null) {
        return false;
    }

    if (nomeAtual == null || nomeAtual.isBlank()) {
        return true;
    }

    if (nomeAtual.equalsIgnoreCase(nomeNovo)) {
        return false;
    }

    boolean atualPareceFiscal = pareceNomeFiscal(nomeAtual);
    boolean novoPareceFiscal = pareceNomeFiscal(nomeNovo);

    if (!atualPareceFiscal && novoPareceFiscal) {
        return false;
    }

    return true;
}

private boolean pareceNomeFiscal(String nome) {
    if (nome == null) {
        return false;
    }

    String n = nome
            .toUpperCase()
            .replace("Ç", "C")
            .replace("Ã", "A")
            .replace("Á", "A")
            .replace("É", "E")
            .replace("Í", "I")
            .replace("Ó", "O")
            .replace("Ú", "U");

    return n.contains(" LTDA")
            || n.contains(" S/A")
            || n.contains(" S.A")
            || n.contains(" EIRELI")
            || n.contains(" COMERCIO")
            || n.contains(" DISTRIBUICAO")
            || n.contains(" COMPANHIA")
            || n.contains(" CIA ")
            || n.contains(" INDUSTRIA");
}

private String somenteNumeros(String texto) {
    if (texto == null) {
        return null;
    }

    String numeros = texto.replaceAll("\\D", "");

    return numeros.isBlank() ? null : numeros;
}
    private Mercado criarMercado(String nome, String cnpj, String endereco) {
        Mercado mercado = new Mercado();
        mercado.setNome(nome);
        mercado.setCnpj(cnpj);
        mercado.setEndereco(endereco);

        return mercadoRepository.save(mercado);
    }

    private void salvarItemCompra(Compra compra, ItemCompraSalvarRequest itemRequest) {
        String nomeProduto = limparTexto(itemRequest.getNome());

        if (nomeProduto == null) {
            nomeProduto = "Produto não identificado";
        }

        Categoria categoria = obterOuCriarCategoria(itemRequest.getCategoria());
        Produto produto = obterOuCriarProduto(nomeProduto, categoria);

        ItemCompra itemCompra = new ItemCompra();
        itemCompra.setCompra(compra);
        
        itemCompra.setProduto(produto);
        itemCompra.setQuantidade(itemRequest.getQuantidade());
        itemCompra.setUnidade(itemRequest.getUnidade());
        itemCompra.setValorUnitario(itemRequest.getValorUnitario());
        itemCompra.setValorTotal(itemRequest.getValorTotal());

        ResultadoNormalizacao normalizacao = UnidadeNormalizer.normalizar(
                itemCompra.getQuantidade(),
                itemCompra.getUnidade(),
                nomeProduto,
                itemCompra.getValorUnitario(),
                itemCompra.getValorTotal()
        );

        itemCompra.setQuantidadeNormalizada(normalizacao.getQuantidade());
        itemCompra.setUnidadeNormalizada(normalizacao.getUnidade());

        if (itemCompra.getQuantidadeNormalizada() != null
                && itemCompra.getQuantidadeNormalizada().compareTo(BigDecimal.ZERO) > 0
                && itemCompra.getValorTotal() != null) {

            BigDecimal precoPorUnidade = itemCompra.getValorTotal().divide(
                    itemCompra.getQuantidadeNormalizada(),
                    4,
                    java.math.RoundingMode.HALF_UP
            );

            itemCompra.setPrecoPorUnidade(precoPorUnidade);
        }

        itemCompraRepository.save(itemCompra);
    }

    private Categoria obterOuCriarCategoria(String nomeCategoria) {
        String nome = limparTexto(nomeCategoria);

        if (nome == null) {
            nome = "Sem categoria";
        }

        String nomeFinal = nome;

        return categoriaRepository.findByNomeIgnoreCase(nomeFinal)
                .orElseGet(() -> {
                    Categoria categoria = new Categoria();
                    categoria.setNome(nomeFinal);
                    return categoriaRepository.save(categoria);
                });
    }
@Transactional
public void excluirCompra(Integer idCompra) {
    if (!compraRepository.existsById(idCompra)) {
        throw new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "Compra não encontrada."
        );
    }

    itemCompraRepository.deleteByCompra_IdCompra(idCompra);
    compraRepository.deleteById(idCompra);
}
   private Produto obterOuCriarProduto(String nomeProduto, Categoria categoria) {
    return produtoRepository.findFirstByNomeIgnoreCase(nomeProduto)
            .map(produtoExistente -> atualizarCategoriaProdutoSeNecessario(produtoExistente, categoria))
            .orElseGet(() -> {
                Produto produto = new Produto();
                produto.setNome(nomeProduto);
                produto.setCategoria(categoria);
                return produtoRepository.save(produto);
            });
}
private Produto atualizarCategoriaProdutoSeNecessario(Produto produto, Categoria novaCategoria) {
    if (novaCategoria == null || novaCategoria.getNome() == null) {
        return produto;
    }

    String nomeNovaCategoria = novaCategoria.getNome();

    if (nomeNovaCategoria.equalsIgnoreCase("Sem categoria")) {
        return produto;
    }

    if (produto.getCategoria() == null) {
        produto.setCategoria(novaCategoria);
        return produtoRepository.save(produto);
    }

    String nomeCategoriaAtual = produto.getCategoria().getNome();

    if (nomeCategoriaAtual == null || nomeCategoriaAtual.equalsIgnoreCase("Sem categoria")) {
        produto.setCategoria(novaCategoria);
        return produtoRepository.save(produto);
    }

    return produto;
}
    private String limparTexto(String texto) {
        if (texto == null || texto.isBlank()) {
            return null;
        }

        return texto.trim();

        
    }
}
