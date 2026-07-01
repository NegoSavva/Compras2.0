package com.compras.compras_api.model.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.Normalizer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class UnidadeNormalizer {

    private static final BigDecimal TOLERANCIA_VALOR = new BigDecimal("0.08");

    private static final Pattern MEDIDA_MULTIPLA_NO_NOME = Pattern.compile(
            "(?i)\\b(\\d+)\\s*[xX]\\s*(\\d+(?:[,.]\\d+)?)\\s*(KG|KILO|KILOS|G|GR|GRAMA|GRAMAS|L|LT|LITRO|LITROS|ML|MILILITRO|MILILITROS)\\b"
    );

    private static final Pattern MEDIDA_NO_NOME = Pattern.compile(
            "(?i)(\\d+(?:[,.]\\d+)?)\\s*(KG|KILO|KILOS|G|GR|GRAMA|GRAMAS|L|LT|LITRO|LITROS|ML|MILILITRO|MILILITROS)\\b"
    );

    private static final Pattern UNIDADE_SOLTA_NO_NOME = Pattern.compile(
            "(?i)\\b(KG|KILO|KILOS|KILOGRAMA|KILOGRAMAS|L|LT|LITRO|LITROS)\\b"
    );

    private static final Pattern INDICADOR_EMBALAGEM_UNIDADE = Pattern.compile(
            "(?i)\\b(PH|PAPEL\\s+HIG|PAPEL\\s+HIGIENICO|FD|FARDO|PCT|PACOTE|C/\\s*\\d+|\\d+R|ESP|ESPONJA|SCOTCH)\\b"
    );

    private static final Pattern HIGIENE_PEQUENO_VOLUME_UNIDADE = Pattern.compile(
            "(?i)\\b(DESOD|DESODORANTE|ROLL\\s*ON|AEROSOL|PERFUME)\\b"
    );

    public static ResultadoNormalizacao normalizar(
            BigDecimal quantidade,
            String unidade
    ) {
        return normalizar(quantidade, unidade, null, null, null);
    }

    public static ResultadoNormalizacao normalizar(
            BigDecimal quantidade,
            String unidade,
            String nomeProduto
    ) {
        return normalizar(quantidade, unidade, nomeProduto, null, null);
    }

    public static ResultadoNormalizacao normalizar(
            BigDecimal quantidade,
            String unidade,
            String nomeProduto,
            BigDecimal valorUnitario,
            BigDecimal valorTotal
    ) {

        if (quantidade == null) {
            quantidade = BigDecimal.ONE;
        }

        String unidadeLimpa = unidade == null
                ? ""
                : unidade.trim().toUpperCase();

        String nomeNormalizado = normalizarTexto(nomeProduto);

        // Alguns produtos vêm como G/ML na NFC-e, mas são embalagens/unitários.
        // Ex.: papel higiênico fardo, esponja c/4, desodorante 50ml.
        if (deveTratarComoUnidade(quantidade, unidadeLimpa, nomeNormalizado)) {
            return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "UN");
        }

        // Quando valorUnitario * quantidade = valorTotal, a quantidade da NFC-e
        // já está na unidade comercial real. Isso corrige itens de balcão/açougue
        // que aparecem como G, mas na prática estão em KG.
        ResultadoNormalizacao porCoerenciaDeValor = normalizarPorCoerenciaDeValor(
                quantidade,
                unidadeLimpa,
                nomeNormalizado,
                valorUnitario,
                valorTotal
        );

        if (porCoerenciaDeValor != null) {
            return porCoerenciaDeValor;
        }

        // Medidas explícitas no nome têm prioridade para embalagens.
        // Ex.: COCA 2L, REF 350ML, HAMB 36X56G.
        ResultadoNormalizacao porNome = normalizarPorNomeProduto(
                quantidade,
                nomeProduto
        );

        if (porNome != null) {
            return porNome;
        }

        ResultadoNormalizacao porUnidade = normalizarPorUnidadeOriginal(
                quantidade,
                unidadeLimpa
        );

        if (!"UN".equals(porUnidade.getUnidade())) {
            return porUnidade;
        }

        return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "UN");
    }

    private static ResultadoNormalizacao normalizarPorCoerenciaDeValor(
            BigDecimal quantidade,
            String unidadeLimpa,
            String nomeNormalizado,
            BigDecimal valorUnitario,
            BigDecimal valorTotal
    ) {
        if (valorUnitario == null || valorTotal == null || quantidade == null) {
            return null;
        }

        if (quantidade.compareTo(BigDecimal.ZERO) <= 0) {
            return null;
        }

        BigDecimal totalCalculado = valorUnitario.multiply(quantidade).setScale(2, RoundingMode.HALF_UP);
        BigDecimal totalInformado = valorTotal.setScale(2, RoundingMode.HALF_UP);
        BigDecimal diferenca = totalCalculado.subtract(totalInformado).abs();

        if (diferenca.compareTo(TOLERANCIA_VALOR) > 0) {
            return null;
        }

        boolean pareceItemPorPeso = quantidade.compareTo(BigDecimal.ONE) < 0
                || contemAlgum(nomeNormalizado, " CAR ", "CARNE", "BOV", "FGO", "FRANGO", "PEITO", "BIF", "ANCH", "TORTA", "QUEIJO", "PRESUNTO", "BALCAO", "KG");

        if (("G".equals(unidadeLimpa) || "GR".equals(unidadeLimpa) || "GRAMA".equals(unidadeLimpa) || "GRAMAS".equals(unidadeLimpa))
                && pareceItemPorPeso
                && !INDICADOR_EMBALAGEM_UNIDADE.matcher(nomeNormalizado).find()) {
            return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "KG");
        }

        if ("UN".equals(unidadeLimpa)
                && quantidade.compareTo(BigDecimal.ONE) < 0
                && pareceItemPorPeso) {
            return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "KG");
        }

        return null;
    }

    private static boolean deveTratarComoUnidade(
            BigDecimal quantidade,
            String unidadeLimpa,
            String nomeNormalizado
    ) {
        if (nomeNormalizado == null || nomeNormalizado.isBlank()) {
            return false;
        }

        if (("G".equals(unidadeLimpa) || "GR".equals(unidadeLimpa) || "GRAMAS".equals(unidadeLimpa))
                && quantidade.compareTo(BigDecimal.ONE) == 0
                && INDICADOR_EMBALAGEM_UNIDADE.matcher(nomeNormalizado).find()) {
            return true;
        }

        if (("ML".equals(unidadeLimpa) || "MILILITRO".equals(unidadeLimpa) || "MILILITROS".equals(unidadeLimpa))
                && quantidade.compareTo(BigDecimal.ONE) == 0
                && HIGIENE_PEQUENO_VOLUME_UNIDADE.matcher(nomeNormalizado).find()) {
            return true;
        }

        return false;
    }

    private static ResultadoNormalizacao normalizarPorUnidadeOriginal(
            BigDecimal quantidade,
            String unidadeLimpa
    ) {
        switch (unidadeLimpa) {

            case "G":
            case "GR":
            case "GRAMA":
            case "GRAMAS":
                return new ResultadoNormalizacao(
                        quantidade.divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP),
                        "KG"
                );

            case "KG":
            case "KILO":
            case "KILOS":
            case "KILOGRAMA":
            case "KILOGRAMAS":
                return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "KG");

            case "ML":
            case "MILILITRO":
            case "MILILITROS":
                return new ResultadoNormalizacao(
                        quantidade.divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP),
                        "L"
                );

            case "L":
            case "LT":
            case "LITRO":
            case "LITROS":
                return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "L");

            default:
                return new ResultadoNormalizacao(quantidade.setScale(4, RoundingMode.HALF_UP), "UN");
        }
    }

    private static ResultadoNormalizacao normalizarPorNomeProduto(
            BigDecimal quantidade,
            String nomeProduto
    ) {
        if (nomeProduto == null || nomeProduto.isBlank()) {
            return null;
        }

        Matcher multiploMatcher = MEDIDA_MULTIPLA_NO_NOME.matcher(nomeProduto);

        if (multiploMatcher.find()) {
            BigDecimal multiplicador = new BigDecimal(multiploMatcher.group(1));
            BigDecimal medida = new BigDecimal(multiploMatcher.group(2).replace(',', '.'));
            String unidadeEncontrada = multiploMatcher.group(3).toUpperCase();
            BigDecimal quantidadeTotal = quantidade.multiply(multiplicador).multiply(medida);

            return converterMedidaParaUnidadeBase(quantidadeTotal, unidadeEncontrada);
        }

        Matcher matcher = MEDIDA_NO_NOME.matcher(nomeProduto);

        if (!matcher.find()) {
            // Alguns itens vendidos por peso vêm da NFC-e com unidade "G",
            // mas a quantidade já está em KG e o nome do produto informa apenas "kg"
            // sem número antes. Ex.: "FGO PEITO CANCAO kg" quantidade 1.290.
            Matcher unidadeSoltaMatcher = UNIDADE_SOLTA_NO_NOME.matcher(nomeProduto);

            if (!unidadeSoltaMatcher.find()) {
                return null;
            }

            String unidadeSolta = unidadeSoltaMatcher.group(1).toUpperCase();

            switch (unidadeSolta) {
                case "KG":
                case "KILO":
                case "KILOS":
                case "KILOGRAMA":
                case "KILOGRAMAS":
                    return new ResultadoNormalizacao(
                            quantidade.setScale(4, RoundingMode.HALF_UP),
                            "KG"
                    );

                case "L":
                case "LT":
                case "LITRO":
                case "LITROS":
                    return new ResultadoNormalizacao(
                            quantidade.setScale(4, RoundingMode.HALF_UP),
                            "L"
                    );

                default:
                    return null;
            }
        }

        BigDecimal medida = new BigDecimal(
                matcher.group(1).replace(',', '.')
        );

        String unidadeEncontrada = matcher.group(2).toUpperCase();
        BigDecimal quantidadeTotal = quantidade.multiply(medida);

        return converterMedidaParaUnidadeBase(quantidadeTotal, unidadeEncontrada);
    }

    private static ResultadoNormalizacao converterMedidaParaUnidadeBase(
            BigDecimal quantidadeTotal,
            String unidadeEncontrada
    ) {
        switch (unidadeEncontrada) {
            case "G":
            case "GR":
            case "GRAMA":
            case "GRAMAS":
                return new ResultadoNormalizacao(
                        quantidadeTotal.divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP),
                        "KG"
                );

            case "KG":
            case "KILO":
            case "KILOS":
                return new ResultadoNormalizacao(
                        quantidadeTotal.setScale(4, RoundingMode.HALF_UP),
                        "KG"
                );

            case "ML":
            case "MILILITRO":
            case "MILILITROS":
                return new ResultadoNormalizacao(
                        quantidadeTotal.divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP),
                        "L"
                );

            case "L":
            case "LT":
            case "LITRO":
            case "LITROS":
                return new ResultadoNormalizacao(
                        quantidadeTotal.setScale(4, RoundingMode.HALF_UP),
                        "L"
                );

            default:
                return null;
        }
    }

    private static boolean contemAlgum(String texto, String... termos) {
        if (texto == null) {
            return false;
        }

        for (String termo : termos) {
            if (texto.contains(termo)) {
                return true;
            }
        }

        return false;
    }

    private static String normalizarTexto(String texto) {
        if (texto == null) {
            return "";
        }

        String semAcento = Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");

        return " " + semAcento.toUpperCase().replaceAll("[^A-Z0-9/]+", " ").replaceAll("\\s+", " ").trim() + " ";
    }
}
