import os
import base64
import time
import pandas as pd
from .model_vencer import BancoDeDados
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import (
    Mail,
    Attachment,
    FileContent,
    FileName,
    FileType,
    Disposition,
    ContentId,
)


class Controlador:
    """
    #!pip install sendgrid
    using SendGrid's Python Library
    https://github.com/sendgrid/sendgrid-python
    """

    def configura_telefone(self, df):
        """Configura o número de telefone do whatsapp"""
        df_modificado = df.copy()
        df_modificado["Whatsapp"] = df_modificado.apply(
            lambda x: (
                "55" + str(x["TEL_COBRANCA"])
                if (len(str(x["TEL_COBRANCA"])) >= 8)
                else (
                    "55" + str(x["TEL_RESPONSAVEL"])
                    if (len(str(x["TEL_RESPONSAVEL"])) >= 8)
                    else "55" + str(x["TEL_INSTALACAO"])
                )
            ),
            axis=1,
        )
        return df_modificado

    def configura_dataframe(self, df):
        """
        Cria a coluna com o link da nota fiscal, formata os tipos de dados e define quais colunas permanecerão no DF
        """
        df_filtrado = df.copy()

        # Exclui clientes de revenda pelo nome cadastrado no banco (NmCliente)
        df_filtrado = df_filtrado[
            ~df_filtrado.NOME.isin(["MS LOGOS SEGURANCA ELETRONICAS LTDA"])
        ]

        df_filtrado = self.configura_telefone(df_filtrado)
        df_filtrado.CONTRATO = df_filtrado.CONTRATO.astype("str")
        df_filtrado["NOTA_FISCAL"] = df_filtrado.NOTA_FISCAL.astype("int64")
        df_filtrado["NOTA_FISCAL"] = df_filtrado.NOTA_FISCAL.astype("str")

        df_filtrado["LINK_NOTA"] = df_filtrado.apply(
            lambda x: (
                "https://nfe.prefeitura.sp.gov.br/contribuinte/notaprint.aspx?ccm=47687347&nf="
                + str(x.NOTA_FISCAL)
                + "&cod="
                + str(x.CODIGO)
                if (pd.notnull(x.NOTA_FISCAL)) & (pd.notnull(x.CODIGO))
                else None
            ),
            axis=1,
        )

        df_filtrado = df_filtrado[
            [
                "CONTRATO",
                "NOME",
                "DIAS",
                "EMAIL",
                "TITULO",
                "MES",
                "VALOR_LIQUIDO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_FATURA",
                "LINK_NOTA",
                "ANO",
                "Whatsapp",
            ]
        ]

        df_filtrado.MES = df_filtrado.MES.astype(int)
        df_filtrado.ANO = df_filtrado.ANO.astype(int)
        df_filtrado.VENCIMENTO = df_filtrado.VENCIMENTO.dt.strftime("%d/%m/%Y")

        return df_filtrado

    def exporta_zenvia(self, df):
        """Formata os dados para exportar o arquivo CSV de disparo na Zenvia"""

        df_modificado = df.copy()
        df_modificado["CODCAMPANHA"] = "RECFINANBLT0010"
        df_modificado.rename(
            columns={"VENCIMENTO": "DATA", "LINHA_DIGITAVEL": "LINHA"}, inplace=True
        )

        df_modificado = df_modificado[
            [
                "Whatsapp",
                "CONTRATO",
                "NOME",
                "DATA",
                "LINHA",
                "CODCAMPANHA",
                # Linhas opcionais
                "VALOR_LIQUIDO",
                "LINK_FATURA",
                "LINK_NOTA",
                "DIAS",
            ]
        ]

        # # =================================
        # # !Dados de teste - 1 linha
        # # =================================
        # df_modificado["Whatsapp"] = "5511973600888"  # 5511973600888 5511988720320

        # Definindo o caminho relativo para o diretório "dados"
        dados = os.path.join(
            os.path.dirname(__file__),
            "..",
            "dados",
            f'Títulos a vencer {time.strftime("%d-%m-%Y %Hh%Mm")}.csv',
        )

        # Normalizando o caminho (para remover redundâncias como "../")
        dados = os.path.normpath(dados)

        # Salvando o arquivo CSV
        df_modificado.to_csv(dados, sep=",", index=False)

        return df_modificado

    def send_email(self, from_mail, df):
        """Configura e envia os emails via Sendgrid"""

        for index, row in df.iterrows():

            # Definindo o caminho relativo para o arquivo "mensagem.html"
            msg_path = os.path.join(
                os.path.dirname(__file__), "..", "utils", "mensagem.html"
            )

            # Normalizando o caminho para remover redundâncias como "../"
            msg_path = os.path.normpath(msg_path)

            # Lê o arquivo html com o corpo da mensagem
            # Abrindo o arquivo usando o caminho relativo
            with open(msg_path, "r", encoding="utf-8") as file:
                msg = file.read()

            # # Lê o arquivo html com o corpo da mensagem
            # with open(
            #     "C:\\Users\\jpereit1\\OneDrive - Johnson Controls\\Documents\\boleto\\a_vencer\\utils\\mensagem.html",
            #     "r",
            #     encoding="utf-8",
            # ) as file:
            #     msg = file.read()

            assunto = "Sua fatura ADT está disponível."

            # Substitui os valores das variáveis no corpo da mensagem
            msg = msg.replace("$NOME", str(row["NOME"]).upper())
            msg = msg.replace("$CONTRATO", str(row["CONTRATO"]))
            msg = msg.replace("$NRTITULO ", str(row["TITULO"]))
            msg = msg.replace("$TXLINHADIGITAVEL", str(row["LINHA_DIGITAVEL"]))
            msg = msg.replace("$LINK_NOTA", str(row["LINK_NOTA"]))
            msg = msg.replace("$DIAS", str(row["DIAS"]))
            msg = msg.replace("$MES", str(row["MES"]))
            msg = msg.replace("$ANO", str(row["ANO"]))
            msg = msg.replace("$VENCIMENTO", str(row["VENCIMENTO"]))
            msg = msg.replace("$VALOR_LIQUIDO", str(row["VALOR_LIQUIDO"]))
            msg = msg.replace("$LINK_FATURA", str(row["LINK_FATURA"]))

            # ==========================================================================================
            #  Início do código para anexar imagem
            # ==========================================================================================
            # Carregue a imagem e codifique-a em base64
            # Definindo o caminho relativo para o arquivo "adt_email.png"
            image_path = os.path.join(
                os.path.dirname(__file__), "..", "utils", "adt_email.png"
            )

            # Normalizando o caminho para remover redundâncias
            image_path = os.path.normpath(image_path)

            # Abrindo e codificando a imagem em base64
            with open(image_path, "rb") as image_file:
                encoded_image = base64.b64encode(image_file.read()).decode()

            # # Carregue a imagem e codifique-a em base64
            # with open(
            #     "C:\\Users\\jpereit1\\OneDrive - Johnson Controls\\Documents\\boleto\\a_vencer\\utils\\adt_email.png",
            #     "rb",
            # ) as image_file:
            #     encoded_image = base64.b64encode(image_file.read()).decode()

            # Crie o anexo da imagem
            attachment = Attachment(
                FileContent(encoded_image),
                FileName("adt_email.png"),
                FileType("image/png"),
                Disposition("inline"),
                ContentId("adt_email"),
            )
            # ==========================================================================================
            #  Fim do código para anexar imagem
            # ==========================================================================================

            message = Mail(
                from_email=from_mail,
                to_emails=row["EMAIL"],
                subject=assunto,
                html_content=msg,
            )

            # Adicione imagem anexo ao e-mail
            message.add_attachment(attachment)

            response = ""
            try:
                sg = SendGridAPIClient(
                    api_key="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"
                )
                response = sg.send(message)

            except Exception as e:
                print(f"Ocorreu um erro: {response}\n{e}")

    def busca_dados(self):
        """Função main"""
        bd = BancoDeDados()
        df = bd.get_data_db()
        df = self.configura_dataframe(df)

        return df
