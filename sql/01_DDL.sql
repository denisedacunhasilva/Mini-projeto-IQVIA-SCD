-- 1. Criação da Tabela Externa Bronze (Lê o arquivo CRU no GCS)
CREATE OR REPLACE EXTERNAL TABLE `lab365-denisec.iqvia_dw.ext_vendas_lote_cru` (
  -- Le-se tudo como STRING para evitar erros de tipagem no arquivo cru
  cod_brick STRING,
  ean STRING,
  cod_produto_catarinense STRING,
  vol_concorrente_indep STRING, -- Vem cru (ex: "1.234,56")
  vol_concorrente_rede STRING,  -- Vem cru (ex: "1.234,56")
  vol_marca_pp STRING,          -- Vem cru (ex: "1.234,56")
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://iqvia_landing/bronze/fato_vendas/*.csv'], -- Pasta Raw no Bucket
  skip_leading_rows = 1, -- Ignora o cabeçalho original
  field_delimiter = ';'  -- Supomos que o Excel gerou com ponto e vírgula
);


-- 2. Tabela de destino (Gold)

CREATE OR REPLACE TABLE `lab365-denisec.iqvia_dw.dim_produto` (
  sk_produto STRING,           -- Chave substituta (UUID)
  id_produto_original STRING,   -- EAN padronizado
  nome_produto STRING,
  cod_produto_catarinense STRING,
  valor_produto FLOAT64,        -- Preço calculado
  data_inicio_validade TIMESTAMP,
  data_fim_validade TIMESTAMP,
  flag_ativo BOOLEAN
);