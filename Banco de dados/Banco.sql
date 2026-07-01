CREATE DATABASE compras2_0
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE compras2_0;

CREATE TABLE mercados (
    id_mercado INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    cnpj VARCHAR(20),
    endereco TEXT
);

CREATE TABLE compras (
    id_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_mercado INT,
    chave_acesso VARCHAR(60) UNIQUE,
    url_nota TEXT NOT NULL,
    data_compra DATETIME,
    valor_total DECIMAL(10,2),
    forma_pagamento VARCHAR(50),
    status_processamento VARCHAR(30) DEFAULT 'PROCESSADO',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_compras_mercados
        FOREIGN KEY (id_mercado)
        REFERENCES mercados(id_mercado)
);

CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT,
    nome VARCHAR(200) NOT NULL,

    CONSTRAINT fk_produtos_categorias
        FOREIGN KEY (id_categoria)
        REFERENCES categorias(id_categoria)
);

CREATE TABLE itens_compra (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT,
    id_produto INT,
    quantidade DECIMAL(10,3),
    unidade VARCHAR(20),
    valor_unitario DECIMAL(10,2),
    valor_total DECIMAL(10,2),

    CONSTRAINT fk_itens_compras
        FOREIGN KEY (id_compra)
        REFERENCES compras(id_compra),

    CONSTRAINT fk_itens_produtos
        FOREIGN KEY (id_produto)
        REFERENCES produtos(id_produto)
);
USE compras2_0;

SELECT * FROM mercados;
SELECT * FROM compras;
SELECT * FROM categorias;
SELECT * FROM produtos;
SELECT * FROM itens_compra;


USE compras2_0;

CREATE TABLE regras_categoria (
    id_regra INT AUTO_INCREMENT PRIMARY KEY,
    palavra_chave VARCHAR(100) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

INSERT INTO regras_categoria (palavra_chave, categoria) VALUES
('imperio', 'Bebidas'),
('lager', 'Bebidas'),
('large', 'Bebidas'),
('cerveja', 'Bebidas'),
('coca', 'Bebidas'),
('guarana', 'Bebidas'),
('pepsi', 'Bebidas'),
('agua', 'Bebidas'),
('suco', 'Bebidas'),

('omo', 'Limpeza'),
('ype', 'Limpeza'),
('detergente', 'Limpeza'),
('sabao', 'Limpeza'),
('amaciante', 'Limpeza'),
('desinfetante', 'Limpeza'),

('sabonete', 'Higiene'),
('shampoo', 'Higiene'),
('condicionador', 'Higiene'),
('creme dental', 'Higiene'),
('papel higienico', 'Higiene'),

('arroz', 'Alimentos'),
('feijao', 'Alimentos'),
('macarrao', 'Alimentos'),
('farinha', 'Alimentos'),
('acucar', 'Alimentos'),
('oleo', 'Alimentos'),

('sadia', 'Carnes/Frios'),
('perdigao', 'Carnes/Frios'),
('frango', 'Carnes'),
('carne', 'Carnes'),
('linguica', 'Carnes'),

('leite', 'Frios e laticínios'),
('queijo', 'Frios e laticínios'),
('iogurte', 'Frios e laticínios'),
('manteiga', 'Frios e laticínios');



USE compras2_0;

SELECT forma_pagamento, COUNT(*) AS quantidade
FROM compras
GROUP BY forma_pagamento;





USE compras2_0;

SELECT id_categoria, nome, nome_relatorio
FROM categorias
ORDER BY nome;



USE compras2_0;

SET SQL_SAFE_UPDATES = 0;

UPDATE categorias
SET nome_relatorio = 'Carnes'
WHERE LOWER(TRIM(nome)) IN (
  'carne',
  'carnes',
  'carnes/frios',
  'açougue',
  'acougue'
);

UPDATE categorias
SET nome_relatorio = 'Bebidas'
WHERE LOWER(TRIM(nome)) IN (
  'bebida',
  'bebidas'
);

UPDATE categorias
SET nome_relatorio = 'Limpeza'
WHERE LOWER(TRIM(nome)) IN (
  'limpeza'
);

UPDATE categorias
SET nome_relatorio = 'Doces'
WHERE LOWER(TRIM(nome)) IN (
  'doce',
  'doces',
  'chocomento'
);

UPDATE categorias
SET nome_relatorio = 'Alimentos'
WHERE LOWER(TRIM(nome)) IN (
  'alimento',
  'alimentos',
  'aliementos',
  'mercearia'
);

UPDATE categorias
SET nome_relatorio = 'Biscoitos e salgadinhos'
WHERE LOWER(TRIM(nome)) IN (
  'biscoitos',
  'salgadinho'
);

SET SQL_SAFE_UPDATES = 1;


USE compras2_0;

SET SQL_SAFE_UPDATES = 0;

UPDATE produtos
SET nome_relatorio = 'Detergente'
WHERE LOWER(nome) LIKE '%det %'
   OR LOWER(nome) LIKE '%detergente%'
   OR LOWER(nome) LIKE '%limpol%'
   OR LOWER(nome) LIKE '%minuano%';

UPDATE produtos
SET nome_relatorio = 'Feijão'
WHERE LOWER(nome) LIKE '%feij%'
   OR LOWER(nome) LIKE '%feijao%'
   OR LOWER(nome) LIKE '%feijão%';

UPDATE produtos
SET nome_relatorio = 'Cerveja'
WHERE LOWER(nome) LIKE '%imperio%'
   OR LOWER(nome) LIKE '%império%'
   OR LOWER(nome) LIKE '%lager%'
   OR LOWER(nome) LIKE '%cerveja%';

UPDATE produtos
SET nome_relatorio = 'Coca-Cola'
WHERE LOWER(nome) LIKE '%coca%';

UPDATE produtos
SET nome_relatorio = 'Sabonete'
WHERE LOWER(nome) LIKE '%sbt %'
   OR LOWER(nome) LIKE '%sabonete%'
   OR LOWER(nome) LIKE '%palm%';

UPDATE produtos
SET nome_relatorio = 'Chocolate'
WHERE LOWER(nome) LIKE '%choc%'
   OR LOWER(nome) LIKE '%garot%'
   OR LOWER(nome) LIKE '%suflair%';

UPDATE produtos
SET nome_relatorio = 'Arroz'
WHERE LOWER(nome) LIKE '%arr %'
   OR LOWER(nome) LIKE '%arroz%';

UPDATE produtos
SET nome_relatorio = 'Leite'
WHERE LOWER(nome) LIKE '%leite%'
   OR LOWER(nome) LIKE '%l semi%'
   OR LOWER(nome) LIKE '%tirol%';

SET SQL_SAFE_UPDATES = 1;

SELECT id_produto, nome, nome_relatorio
FROM produtos
WHERE nome_relatorio IS NOT NULL
ORDER BY nome_relatorio, nome;

USE compras2_0;
UPDATE itens_compra
SET unidade_normalizada = unidade;
SET SQL_SAFE_UPDATES = 1;



ALTER TABLE itens_compra
ADD COLUMN preco_por_unidade DECIMAL(14,4);


SELECT

quantidade_normalizada,
unidade_normalizada,
preco_por_unidade
FROM itens_compra;