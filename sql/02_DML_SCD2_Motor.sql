BEGIN
  -- ==========================================================================
  -- 1. CAMADA SILVER: STAGING, LIMPEZA E PADRONIZAÇÃO
  -- Aqui transformamos o dado bruto da External Table em dado processado.
  -- ==========================================================================
  CREATE OR REPLACE TEMP TABLE staging_produto_limpa AS
  SELECT DISTINCT
    -- Padronização de IDs (Conforme solicitado: EAN 15 e Catarinense 13)
    LPAD(TRIM(ean), 15, '0') AS id_produto_original,
    LPAD(TRIM(cod_produto_catarinense), 13, '0') AS cod_produto_catarinense,
    
    -- Mapeamento de Nomes (Regra de Negócio)
    CASE 
      WHEN ean LIKE '%32689150' THEN 'Buscopan Composto Drágeas'
      WHEN ean LIKE '%42110200' THEN 'Nivea Creme Hidratante Soft 49g'
      WHEN ean LIKE '%71826223' THEN 'Desodorante Stick ALVA cristal natural 120G'
      WHEN ean LIKE '%42176763' THEN 'Nivea Gel Esfoliante Facial 75ml'
      WHEN ean LIKE '%42277217' THEN 'Nivea Creme Lata Azul 29g'
      WHEN ean LIKE '%42355014' THEN 'Nivea Água Micelar Expert 125ml'
      WHEN ean LIKE '%42355465' THEN 'Nivea Men Creme Hidratante 4 em 1 30g'
      WHEN ean LIKE '%42360407' THEN 'Nivea Creme Facial Nutritivo 100g'
      WHEN ean LIKE '%42360414' THEN 'Nivea Creme Facial Antissinais 100g'
      WHEN ean LIKE '%42389248' THEN 'Nivea Creme Facial Noturno 100g'
      ELSE 'Produto Novo/Desconhecido'
    END AS nome_produto,

    -- Cálculo de Valor com tratamento de NULL e conversão de decimal (vírgula para ponto)
    ROUND(
      SAFE_DIVIDE(
        SAFE_CAST(REPLACE(REPLACE(COALESCE(vol_marca_pp, '0'), '.', ''), ',', '.') AS FLOAT64), 
        10
      ) + 5.0, 2
    ) AS valor_produto

  FROM `lab365-denisec.iqvia_dw.ext_vendas_lote_cru`
  WHERE ean IS NOT NULL AND ean <> '';

  -- ==========================================================================
  -- 2. CAMADA GOLD: LOGICA SCD TIPO 2 (DIMENSÃO DE MUDANÇA LENTA)
  -- ==========================================================================

  -- PASSO A: Fechar registros antigos se o Preço ou Nome mudaram
  UPDATE `lab365-denisec.iqvia_dw.dim_produto` d
  SET data_fim_validade = CURRENT_TIMESTAMP(), 
      flag_ativo = FALSE
  FROM staging_produto_limpa s
  WHERE d.id_produto_original = s.id_produto_original 
    AND d.flag_ativo = TRUE 
    AND (d.valor_produto <> s.valor_produto OR d.nome_produto <> s.nome_produto);

  -- PASSO B: Exclusão Lógica (Inativar produtos que saíram do arquivo original)
  UPDATE `lab365-denisec.iqvia_dw.dim_produto`
  SET data_fim_validade = CURRENT_TIMESTAMP(), 
      flag_ativo = FALSE
  WHERE flag_ativo = TRUE 
    AND id_produto_original NOT IN (SELECT id_produto_original FROM staging_produto_limpa);

  -- PASSO C: Inserir novos registros (Novos produtos ou Novas versões de preço)
  INSERT INTO `lab365-denisec.iqvia_dw.dim_produto` 
    (sk_produto, id_produto_original, nome_produto, cod_produto_catarinense, valor_produto, data_inicio_validade, flag_ativo)
  SELECT 
    GENERATE_UUID(), -- Gera a Surrogate Key única
    s.id_produto_original, 
    s.nome_produto, 
    s.cod_produto_catarinense, 
    s.valor_produto, 
    CURRENT_TIMESTAMP(), 
    TRUE
  FROM staging_produto_limpa s
  WHERE NOT EXISTS (
    SELECT 1 FROM `lab365-denisec.iqvia_dw.dim_produto` d 
    WHERE d.id_produto_original = s.id_produto_original 
      AND d.flag_ativo = TRUE 
      AND d.valor_produto = s.valor_produto -- Só insere se o preço atual for diferente do que já temos ativo
  );

  -- Mensagem de log interna (Opcional para Debug)
  SELECT "Processamento SCD2 Concluído com Sucesso!" AS status;

END;