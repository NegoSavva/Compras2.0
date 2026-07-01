package com.compras.compras_api.model.service;


import com.compras.compras_api.model.dto.ItemExtraidoResponse;
import com.compras.compras_api.model.dto.NotaLeituraResponse;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;
import java.math.RoundingMode;

import com.compras.compras_api.model.RegraCategoria;
import com.compras.compras_api.repository.RegraCategoriaRepository;
import lombok.RequiredArgsConstructor;

import java.math.BigDecimal;
import java.net.URI;
import java.text.Normalizer;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class NfceExtractorService {
private String classificarPorRegrasDoBanco(String nomeProduto) {
    if (nomeProduto == null || nomeProduto.isBlank()) {
        return null;
    }

    String nomeNormalizado = normalizar(nomeProduto);

    List<RegraCategoria> regras = regraCategoriaRepository.findByAtivoTrueOrderByPalavraChaveAsc();

    for (RegraCategoria regra : regras) {
        String palavraChave = normalizar(regra.getPalavraChave());

        if (palavraChave == null || palavraChave.isBlank()) {
            continue;
        }

        if (nomeNormalizado.contains(palavraChave)) {
            return regra.getCategoria();
        }
    }

    return null;
}
    private final RegraCategoriaRepository regraCategoriaRepository;

    public NotaLeituraResponse extrair(String url) {
    url = normalizarUrl(url);

    validarUrl(url);

    try {
        Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0")
                    .timeout(15000)
                    .followRedirects(true)
                    .get();

            NotaLeituraResponse response = new NotaLeituraResponse();

            String textoPagina = doc.text();

            response.setUrlNota(url);
            response.setChaveAcesso(extrairChaveAcesso(url + " " + textoPagina));
            response.setMercadoNome(extrairMercadoNome(doc, textoPagina));
            response.setMercadoCnpj(extrairCnpj(textoPagina));
            response.setMercadoEndereco(extrairEndereco(textoPagina));
            response.setDataCompra(extrairDataCompra(textoPagina));
            response.setFormaPagamento(extrairFormaPagamento(textoPagina));
            response.setValorTotal(extrairValorTotal(textoPagina));
            response.setStatusProcessamento("PENDENTE_CONFERENCIA");

            extrairItens(doc, response);

           BigDecimal totalItens = calcularTotalItens(response);

if (response.getValorTotal() == null || response.getValorTotal().compareTo(BigDecimal.ZERO) <= 0) {
    response.setValorTotal(totalItens);
} else if (
        totalItens.compareTo(BigDecimal.ZERO) > 0
                && totalItens.compareTo(response.getValorTotal()) != 0
) {
    // Se a soma dos itens for diferente do total da nota, mantém o total oficial da nota,
    // mas marca como pendente para você conferir na tela.
    response.setStatusProcessamento("PENDENTE_CONFERENCIA");
}

            if (response.getItens().isEmpty()) {
                response.setStatusProcessamento("DADOS_INCOMPLETOS");
            }

            return response;
        } catch (Exception e) {
            throw new IllegalArgumentException(
                    "Não foi possível extrair os dados reais da NFC-e. " +
                    "A página pode estar bloqueando acesso automático ou ter um layout diferente. " +
                    "Detalhe: " + e.getMessage()
            );
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
    private void validarUrl(String url) {
        if (url == null || url.isBlank()) {
            throw new IllegalArgumentException("A URL da NFC-e não pode estar vazia.");
        }

        try {
            URI uri = URI.create(url);

            if (uri.getScheme() == null || uri.getHost() == null) {
                throw new IllegalArgumentException("URL inválida.");
            }

            String normalizada = url.toLowerCase();

            boolean pareceNota = normalizada.contains("nfce")
                    || normalizada.contains("nfe")
                    || normalizada.contains("sefaz")
                    || normalizada.contains("fazenda");

            if (!pareceNota) {
                throw new IllegalArgumentException("A URL informada não parece ser de NFC-e.");
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("URL inválida.");
        }
    }

    private String extrairChaveAcesso(String texto) {
        Matcher matcher = Pattern.compile("\\d{44}").matcher(texto);

        if (matcher.find()) {
            return matcher.group();
        }

        return null;
    }

    private String extrairMercadoNome(Document doc, String textoPagina) {
        String porSeletor = primeiroTextoNaoVazio(
                doc,
                ".txtTopo",
                "#u20",
                ".nomeEmitente",
                ".emitente",
                "h1",
                "h2",
                "title"
        );

        if (porSeletor != null) {
            return limparTexto(porSeletor);
        }

        String[] linhas = textoPagina.split("\\s{2,}|\\n");

        for (String linha : linhas) {
            String texto = limparTexto(linha);

            if (texto != null && texto.length() > 5 && !normalizar(texto).contains("nota fiscal")) {
                return texto;
            }
        }

        return "Mercado não identificado";
    }

    private String extrairCnpj(String texto) {
        Matcher matcher = Pattern.compile("(\\d{2}\\.\\d{3}\\.\\d{3}/\\d{4}-\\d{2})").matcher(texto);

        if (matcher.find()) {
            return matcher.group(1);
        }

        Matcher apenasNumeros = Pattern.compile("CNPJ\\s*:?\\s*(\\d{14})", Pattern.CASE_INSENSITIVE).matcher(texto);

        if (apenasNumeros.find()) {
            return formatarCnpj(apenasNumeros.group(1));
        }

        return null;
    }

    private String extrairEndereco(String texto) {
        Matcher matcher = Pattern.compile(
                "(Endere[cç]o\\s*:?\\s*)(.*?)(CNPJ|Inscri[cç][aã]o|IE|Documento|NFC-e)",
                Pattern.CASE_INSENSITIVE
        ).matcher(texto);

        if (matcher.find()) {
            return limparTexto(matcher.group(2));
        }

        return null;
    }

    private LocalDateTime extrairDataCompra(String texto) {
        Pattern pattern = Pattern.compile(
                "(\\d{2}/\\d{2}/\\d{4})\\s*(\\d{2}:\\d{2}:\\d{2})?"
        );

        Matcher matcher = pattern.matcher(texto);

        if (matcher.find()) {
            String data = matcher.group(1);
            String hora = matcher.group(2) != null ? matcher.group(2) : "00:00:00";

            try {
                DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
                return LocalDateTime.parse(data + " " + hora, formatter);
            } catch (Exception ignored) {
                return null;
            }
        }

        return null;
    }

   private String extrairFormaPagamento(String texto) {
    String normalizado = normalizar(texto);

    if (contemQualquerTermoPagamento(normalizado,
            "pix")) {
        return "PIX";
    }

    if (contemQualquerTermoPagamento(normalizado,
            "cartao de credito",
            "cartao credito",
            "credito")) {
        return "Cartão de crédito";
    }

    if (contemQualquerTermoPagamento(normalizado,
            "cartao de debito",
            "cartao debito",
            "debito")) {
        return "Cartão de débito";
    }

    if (contemQualquerTermoPagamento(normalizado,
            "dinheiro",
            "especie")) {
        return "Dinheiro";
    }

    if (contemQualquerTermoPagamento(normalizado,
            "vale alimentacao",
            "vale-alimentacao",
            "cartao alimentacao",
            "cartao de alimentacao",
            "ticket alimentacao",
            "alelo alimentacao",
            "sodexo alimentacao",
            "vr alimentacao",
            "ben alimentacao",
            "alimentacao")) {
        return "Vale alimentação";
    }

    if (contemQualquerTermoPagamento(normalizado,
            "vale refeicao",
            "vale-refeicao",
            "cartao refeicao",
            "cartao de refeicao",
            "ticket refeicao",
            "ticket restaurante",
            "alelo refeicao",
            "sodexo refeicao",
            "vr refeicao",
            "ben refeicao",
            "refeicao")) {
        return "Vale refeição";
    }

    if (contemQualquerTermoPagamento(normalizado,
            "voucher",
            "cartao beneficio",
            "cartao beneficios",
            "beneficio",
            "beneficios")) {
        return "Vale/benefício";
    }

    return extrairFormaPagamentoPorTrecho(texto);
}

private boolean contemQualquerTermoPagamento(String textoNormalizado, String... termos) {
    for (String termo : termos) {
        if (contemTermoPagamento(textoNormalizado, termo)) {
            return true;
        }
    }

    return false;
}

private boolean contemTermoPagamento(String textoNormalizado, String termo) {
    if (textoNormalizado == null || termo == null) {
        return false;
    }

    String termoNormalizado = normalizar(termo);

    if (termoNormalizado.isBlank()) {
        return false;
    }

    String regex = "(^|[^a-z0-9])"
            + Pattern.quote(termoNormalizado)
            + "([^a-z0-9]|$)";

    return Pattern.compile(regex).matcher(textoNormalizado).find();
}
private String extrairFormaPagamentoPorTrecho(String texto) {
    if (texto == null || texto.isBlank()) {
        return "Não identificado";
    }

    String[] padroes = {
            "Forma\\s+de\\s+pagamento\\s*:?\\s*([A-Za-zÀ-ÿ0-9\\s\\-\\.]+)",
            "Meio\\s+de\\s+pagamento\\s*:?\\s*([A-Za-zÀ-ÿ0-9\\s\\-\\.]+)",
            "Pagamento\\s*:?\\s*([A-Za-zÀ-ÿ0-9\\s\\-\\.]+)"
    };

    for (String padrao : padroes) {
        Matcher matcher = Pattern.compile(padrao, Pattern.CASE_INSENSITIVE).matcher(texto);

        if (matcher.find()) {
            String forma = limparTexto(matcher.group(1));

            if (forma != null && forma.length() > 2) {
                if (forma.length() > 40) {
                    forma = forma.substring(0, 40).trim();
                }

                return forma;
            }
        }
    }

    return "Não identificado";
}
   private BigDecimal extrairValorTotal(String texto) {
    String[] padroes = {
            "Valor\\s+total\\s+da\\s+nota\\s*R?\\$?\\s*([0-9\\.]+[,.][0-9]{2})",
            "Valor\\s+total\\s*R?\\$?\\s*([0-9\\.]+[,.][0-9]{2})",
            "Valor\\s+a\\s+pagar\\s*R?\\$?\\s*([0-9\\.]+[,.][0-9]{2})",
            "TOTAL\\s+R?\\$?\\s*([0-9\\.]+[,.][0-9]{2})"
    };

    for (String padrao : padroes) {
        Matcher matcher = Pattern.compile(padrao, Pattern.CASE_INSENSITIVE).matcher(texto);

        if (matcher.find()) {
            return parseDecimal(matcher.group(1));
        }
    }

    return BigDecimal.ZERO;
}
    private void extrairItens(Document doc, NotaLeituraResponse response) {
        Elements linhas = doc.select(
                "#tabResult tr, " +
                "table tr, " +
                ".prod, " +
                ".produto, " +
                ".item, " +
                "li"
        );

        for (Element linha : linhas) {
            ItemExtraidoResponse item = tentarExtrairItem(linha);

            if (item != null) {
                response.getItens().add(item);
            }
        }

        removerDuplicadosSimples(response);
    }

    private ItemExtraidoResponse tentarExtrairItem(Element linha) {
        String texto = limparTexto(linha.text());

        if (texto == null || texto.length() < 8) {
            return null;
        }

        String textoNormalizado = normalizar(texto);

        boolean pareceProduto = textoNormalizado.contains("qtd")
                || textoNormalizado.contains("qtde")
                || textoNormalizado.contains("un")
                || textoNormalizado.contains("vl unit")
                || textoNormalizado.contains("valor");

        if (!pareceProduto) {
            return null;
        }

        String nome = primeiroTextoNaoVazio(
                linha,
                ".txtTit",
                ".fixo-prod-serv-descricao",
                ".prodNome",
                ".descricao",
                "[class*=descricao]",
                "[class*=produto]"
        );

        if (nome == null) {
            nome = extrairNomeProdutoPorTexto(texto);
        }

        if (nome == null || nome.length() < 2) {
            return null;
        }

        BigDecimal quantidade = extrairDecimalPorPadroes(
                texto,
                "Qtde?\\.?\\s*:?\\s*([0-9]+[,.]?[0-9]*)",
                "Qtd\\.?\\s*:?\\s*([0-9]+[,.]?[0-9]*)",
                "Quantidade\\s*:?\\s*([0-9]+[,.]?[0-9]*)"
        );

        if (quantidade == null) {
            quantidade = BigDecimal.ONE;
        }

        String unidade = extrairUnidade(texto);

       BigDecimal valorUnitario = extrairDecimalPorPadroes(
        texto,
        "Vl\\.?\\s*Unit\\.?\\s*:?\\s*([0-9]+[,.][0-9]{2})",
        "Valor\\s*Unit[aá]rio\\s*:?\\s*([0-9]+[,.][0-9]{2})",
        "Unit[aá]rio\\s*:?\\s*([0-9]+[,.][0-9]{2})",
        "Vlr\\.?\\s*Unit\\.?\\s*:?\\s*([0-9]+[,.][0-9]{2})"
);

BigDecimal valorTotal = extrairValorTotalItem(linha, texto);

if (valorUnitario == null) {
    valorUnitario = BigDecimal.ZERO;
}

if (valorTotal == null) {
    valorTotal = BigDecimal.ZERO;
}

// Se o total veio zerado, mas temos quantidade e unitário, calcula o total.
if (
        valorTotal.compareTo(BigDecimal.ZERO) <= 0
                && quantidade.compareTo(BigDecimal.ZERO) > 0
                && valorUnitario.compareTo(BigDecimal.ZERO) > 0
) {
    valorTotal = quantidade.multiply(valorUnitario);
}

// Se o unitário veio zerado, mas temos quantidade e total, calcula o unitário.
if (
        valorUnitario.compareTo(BigDecimal.ZERO) <= 0
                && quantidade.compareTo(BigDecimal.ZERO) > 0
                && valorTotal.compareTo(BigDecimal.ZERO) > 0
) {
    valorUnitario = valorTotal.divide(
            quantidade,
            2,
            RoundingMode.HALF_UP
    );
}

// Se ainda assim o total for zero, mantém o item, mas com valor zero.
// Não vamos mais descartar o produto, porque isso pode sumir com itens da nota.
String nomeLimpo = limparTexto(nome);
String categoria = classificarCategoriaProduto(nomeLimpo);

return new ItemExtraidoResponse(
        nomeLimpo,
        quantidade,
        unidade,
        valorUnitario,
        valorTotal,
        categoria
);
    };
private String classificarCategoriaProduto(String nomeProduto) {
    String categoriaPorRegra = classificarPorRegrasDoBanco(nomeProduto);

    if (categoriaPorRegra != null) {
        return categoriaPorRegra;
    }

    String nome = normalizar(nomeProduto);

    // o restante das regras antigas continua abaixo

    if (contemQualquer(nome,
            "arroz", "feijao", "macarrao", "farinha", "acucar", "sal",
            "oleo", "azeite", "molho", "extrato", "milho", "ervilha",
            "biscoito", "bolacha", "cereal", "aveia", "cafe", "achocolatado")) {
        return "Alimentos";
    }

   if (contemQualquer(nome,
        "refrigerante", "refri", "coca", "coca cola", "pepsi",
        "guarana", "guaraná", "fanta", "sprite",
        "suco", "nectar", "néctar",
        "agua", "água", "agua mineral", "água mineral",
        "energetico", "energético", "red bull", "monster",
        "cha", "chá", "mate", "ice tea",
        "isotonico", "isotônico", "gatorade",
        "bebida",
        "cerveja", "pilsen", "lager", "large", "império", "imperio",
        "skol", "brahma", "itaipava", "heineken", "budweiser", "amstel",
        "stella", "original")) {
    return "Bebidas";
}

    if (contemQualquer(nome,
            "leite", "queijo", "mussarela", "mucarela", "iogurte",
            "requeijao", "manteiga", "margarina", "creme de leite",
            "leite condensado")) {
        return "Frios e laticínios";
    }

    if (contemQualquer(nome,
            "carne", "frango", "bovina", "suina", "linguica", "salsicha",
            "hamburguer", "peixe", "tilapia", "costela", "patinho",
            "acém", "file", "filé")) {
        return "Carnes";
    }

    if (contemQualquer(nome,
            "banana", "maca", "maça", "laranja", "limao", "limão",
            "tomate", "cebola", "batata", "cenoura", "alface",
            "abacate", "uva", "mamao", "mamão", "melancia", "verdura",
            "legume", "fruta")) {
        return "Hortifruti";
    }

    if (contemQualquer(nome,
            "pao", "pão", "bolo", "sonho", "rosca", "padaria",
            "torrada", "bisnaguinha")) {
        return "Padaria";
    }

    if (contemQualquer(nome,
            "detergente", "sabao", "sabão", "amaciante", "desinfetante",
            "agua sanitaria", "água sanitária", "limpador", "esponja",
            "multiuso", "alcool", "álcool", "cloro", "lava roupas")) {
        return "Limpeza";
    }

    if (contemQualquer(nome,
            "sabonete", "shampoo", "condicionador", "creme dental",
            "pasta dental", "escova dental", "desodorante", "papel higienico",
            "papel higiênico", "absorvente", "fralda", "barbeador")) {
        return "Higiene";
    }

    if (contemQualquer(nome,
            "racao", "ração", "pet", "gato", "cachorro", "areia sanitaria",
            "areia sanitária")) {
        return "Pet";
    }

    if (contemQualquer(nome,
            "copo", "prato", "panela", "talher", "pilha", "lampada",
            "lâmpada", "pote", "saco lixo", "sacola")) {
        return "Utilidades";
    }

    return "Sem categoria";
}

private boolean contemQualquer(String texto, String... palavras) {
    for (String palavra : palavras) {
        if (texto.contains(normalizar(palavra))) {
            return true;
        }
    }

    return false;
}
    private String extrairNomeProdutoPorTexto(String texto) {
        String[] separadores = {
                "Qtde",
                "Qtd",
                "Quantidade",
                "UN:",
                "Vl. Unit",
                "Valor Unitário",
                "Valor"
        };

        String nome = texto;

        for (String separador : separadores) {
            int index = normalizar(nome).indexOf(normalizar(separador));

            if (index > 0) {
                nome = nome.substring(0, index);
            }
        }

        nome = nome.replaceAll("^\\d+\\s*-?\\s*", "");

        return limparTexto(nome);
    }

    private String extrairUnidade(String texto) {
        Matcher matcher = Pattern.compile("(UN|KG|G|L|ML|CX|PC|PCT)", Pattern.CASE_INSENSITIVE).matcher(texto);

        if (matcher.find()) {
            return matcher.group(1).toUpperCase();
        }

        return "UN";
    }

   private BigDecimal extrairValorTotalItem(Element linha, String texto) {
    String porSeletor = primeiroTextoNaoVazio(
            linha,
            ".valor",
            ".fixo-prod-serv-vb",
            ".total",
            "[class*=valor]",
            "[class*=total]"
    );

    if (porSeletor != null) {
        BigDecimal valor = parseDecimal(porSeletor);

        if (valor.compareTo(BigDecimal.ZERO) > 0) {
            return valor;
        }
    }

    BigDecimal porPadrao = extrairDecimalPorPadroes(
            texto,
            "Vl\\.?\\s*Total\\s*:?\\s*([0-9]+[,.][0-9]{2})",
            "Valor\\s*Total\\s*:?\\s*([0-9]+[,.][0-9]{2})",
            "Vlr\\.?\\s*Total\\s*:?\\s*([0-9]+[,.][0-9]{2})",
            "Total\\s*do\\s*Item\\s*:?\\s*([0-9]+[,.][0-9]{2})",
            "Valor\\s*R?\\$?\\s*([0-9]+[,.][0-9]{2})"
    );

    if (porPadrao != null && porPadrao.compareTo(BigDecimal.ZERO) > 0) {
        return porPadrao;
    }

    Matcher matcher = Pattern.compile("([0-9]+[,.][0-9]{2})").matcher(texto);

    BigDecimal ultimoValor = null;

    while (matcher.find()) {
        ultimoValor = parseDecimal(matcher.group(1));
    }

    return ultimoValor;
}
    private BigDecimal extrairDecimalPorPadroes(String texto, String... padroes) {
        for (String padrao : padroes) {
            Matcher matcher = Pattern.compile(padrao, Pattern.CASE_INSENSITIVE).matcher(texto);

            if (matcher.find()) {
                return parseDecimal(matcher.group(1));
            }
        }

        return null;
    }

    private BigDecimal parseDecimal(String texto) {
        if (texto == null) {
            return BigDecimal.ZERO;
        }

        String normalizado = texto
                .replaceAll("[^0-9,\\.]", "")
                .replace(".", "")
                .replace(",", ".");

        if (normalizado.isBlank()) {
            return BigDecimal.ZERO;
        }

        try {
            return new BigDecimal(normalizado);
        } catch (Exception e) {
            return BigDecimal.ZERO;
        }
    }

    private String primeiroTextoNaoVazio(Document doc, String... seletores) {
        for (String seletor : seletores) {
            Element element = doc.selectFirst(seletor);

            if (element != null) {
                String texto = limparTexto(element.text());

                if (texto != null) {
                    return texto;
                }
            }
        }

        return null;
    }

    private String primeiroTextoNaoVazio(Element element, String... seletores) {
        for (String seletor : seletores) {
            Element encontrado = element.selectFirst(seletor);

            if (encontrado != null) {
                String texto = limparTexto(encontrado.text());

                if (texto != null) {
                    return texto;
                }
            }
        }

        return null;
    }

    private BigDecimal calcularTotalItens(NotaLeituraResponse response) {
        return response.getItens()
                .stream()
                .map(ItemExtraidoResponse::getValorTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private void removerDuplicadosSimples(NotaLeituraResponse response) {
        response.setItens(
                response.getItens()
                        .stream()
                        .distinct()
                        .toList()
        );
    }

    private String limparTexto(String texto) {
        if (texto == null) {
            return null;
        }

        String limpo = texto
                .replace("\u00A0", " ")
                .replaceAll("\\s+", " ")
                .trim();

        return limpo.isBlank() ? null : limpo;
    }

    private String normalizar(String texto) {
        if (texto == null) {
            return "";
        }

        String semAcento = Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");

        return semAcento.toLowerCase();
    }

    private String formatarCnpj(String cnpj) {
        if (cnpj == null || cnpj.length() != 14) {
            return cnpj;
        }

        return cnpj.substring(0, 2) + "."
                + cnpj.substring(2, 5) + "."
                + cnpj.substring(5, 8) + "/"
                + cnpj.substring(8, 12) + "-"
                + cnpj.substring(12, 14);
    }
}