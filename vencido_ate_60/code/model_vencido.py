import pyodbc
import pandas as pd
import warnings
import os

warnings.filterwarnings("ignore")


class BancoDeDados:
    # ===================================================
    # Métodos do banco (CRUD)
    # ===================================================
    def __init__(self) -> None:
        self.con_string = (
            "Driver={SQL Server};"
            "Server=10.67.99.10\MSSQLSERVER2019;"
            "Database=DATA_WAREHOUSE;"
            "UID=userCustomerServices;"
            "PWD=userCustomerServices@ADT_2023*;"
            "Trusted_Connection=no;"
        )

        # Caminho relativo para o arquivo SQL (subindo um nível)
        self.sql_file = os.path.join(
            os.path.dirname(__file__), "..", "utils", "QUERY_FINAL.sql"
        )

        # Normaliza o caminho (remove redundâncias como "../")
        self.sql_file = os.path.normpath(self.sql_file)

    # Pega dados do banco
    def get_data_db(self):
        """Pega os dados da tabela"""
        try:
            # Usando a instrução "with" para garantir que a conexão seja fechada automaticamente
            with pyodbc.connect(self.con_string) as connection:
                # Abrindo e lendo o conteúdo do arquivo SQL
                with open(self.sql_file, "r", encoding="utf-8") as file:
                    query = file.read()

                # Execute a leitura dos dados
                df = pd.read_sql(query, connection)
                return df
        except Exception as error:
            print("UMA EXCECAO OCORREU:", error)
