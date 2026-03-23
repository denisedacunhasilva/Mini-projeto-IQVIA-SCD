import os
import pandas as pd
from datetime import datetime

def executar_extracao(arquivos_fontes, pasta_destino):
    print(f"\n--- [1] Iniciando Extração e Conversão: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')} ---")
    
    if not os.path.exists(pasta_destino):
        os.makedirs(pasta_destino)

    arquivos_convertidos = []

    for arquivo_xlsx in arquivos_fontes:
        if os.path.exists(arquivo_xlsx):
            nome_arquivo = os.path.basename(arquivo_xlsx)
            nome_csv = nome_arquivo.replace('.xlsx', '.csv')
            caminho_csv = os.path.join(pasta_destino, nome_csv)
            
            try:
                # 1. Lemos tudo como string para evitar que o Pandas converta para número
                df = pd.read_excel(arquivo_xlsx, dtype=str)
                
                # 2. A MÁGICA: Forçamos o preenchimento de zeros (Padding)
                # O EAN costuma ter 13 dígitos. Se o seu padrão for outro, mude o número abaixo.
                if 'EAN' in df.columns:
                    df['EAN'] = df['EAN'].str.strip().str.zfill(13)
                
                if 'Cod Prod Catarinense' in df.columns:
                    df['Cod Prod Catarinense'] = df['Cod Prod Catarinense'].str.strip().str.zfill(6)
                
                # 3. Salvamos o CSV
                df.to_csv(caminho_csv, index=False, sep=';', encoding='utf-8')
                
                print(f"✅ Sucesso: {nome_csv} gerado com Zeros à Esquerda!")
                arquivos_convertidos.append(caminho_csv)
                
            except Exception as e:
                print(f"❌ Erro ao processar {nome_arquivo}: {e}")
    
    return arquivos_convertidos

if __name__ == "__main__":
    meus_arquivos = ['data/raw/MS_12_2022_sample.xlsx', 'data/raw/filial-brick_sample.xlsx']
    pasta_output = 'data/processed'
    executar_extracao(meus_arquivos, pasta_output)