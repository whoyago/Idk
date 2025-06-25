import streamlit as st
import pandas as pd
import time
from .controler_vencido import Controlador

def run():
    ctr = Controlador()
# =======================================================================
# Página Principal
# =======================================================================
# Título da página
st.title("🤖 Débito Vencidos até 60 Dias")

st.write("------------------------------------------------------------------------")

# Inserir um espaço em branco
st.markdown("")

# =======================================================================
# Página Lateral
# =======================================================================
# Título no menu lateral
st.sidebar.title("Filtros de ações")
st.sidebar.markdown("## Gerar base")

email_origem = "financeirobr@adt.com.br"

df = pd.DataFrame()

if st.sidebar.button("Gerar base", type="primary"):
    with st.spinner("Carregando..."):
        df = ctr.busca_dados()

        # df = df.dropna()

        # ===============================================
        # Inserir dados de teste (financeiro) => início
        # ===============================================
        lista = [list(df.iloc[-1])]
        dados_teste = [
            [
                "237495",
                "JULIANA PEREIRA",
                "juliana.1.pereira-ext@jci.com",
                "TITULO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_NOTA",
                "5511982144968",
            ],
            [
                "237495",
                "EDIELC MESQUITA",
                "edielc.mesquitarodrigues-ext@adt.com.br",
                "TITULO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_NOTA",
                "5511971377095",
            ],
            [
                "237495",
                "ALMIR MARTINS LOPES",
                "almir.martinslopes@jci.com",
                "TITULO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_NOTA",
                "5511973600888",
            ],
        ]

        for dados in dados_teste:
            aux = lista[-1].copy()
            dados[3] = aux[3]
            dados[4] = aux[4]
            dados[5] = aux[5]
            dados[6] = aux[6]
            dados[7] = aux[7]

        df_teste = pd.DataFrame(dados_teste, columns=df.columns)

        df = pd.concat([df, df_teste]).reset_index(drop=True)
        print(df.tail(6))
        # ===============================================
        # Inserir dados de teste (financeiro) => Fim
        # ===============================================

        time.sleep(0.1)
        st.write(f"{df.shape[0]} clientes selecionados")

        st.dataframe(
            df,
            hide_index=True,
            width=760,
            height=250,
        )

    st.success("Base gerada!")


st.sidebar.write("-------------------------------------------------------------------")

st.sidebar.markdown("## Enviar e-mails")

# Menu de opções
options = st.sidebar.multiselect(
    "Selecione uma ou mais opções:",
    ["Enviar e-mails", "Exportar arquivo CSV"],
)

if st.sidebar.button("Finalizar envios", type="primary"):
    with st.spinner("Carregando..."):
        df = ctr.busca_dados()

        # ===============================================
        # Inserir dados de teste (financeiro) => início
        # ===============================================
        lista = [list(df.iloc[-1])]
        dados_teste = [
            [
                "237495",
                "JULIANA PEREIRA",
                "juliana.1.pereira-ext@jci.com",
                "TITULO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_NOTA",
                "5511982144968",
            ],
            [
                "237495",
                "EDIELC MESQUITA",
                "edielc.mesquitarodrigues-ext@adt.com.br",
                "TITULO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_NOTA",
                "5511971377095",
            ],
            [
                "237495",
                "ALMIR MARTINS LOPES",
                "almir.martinslopes@jci.com",
                "TITULO",
                "VENCIMENTO",
                "LINHA_DIGITAVEL",
                "NOTA_FISCAL",
                "LINK_NOTA",
                "5511973600888",
            ],
        ]

        for dados in dados_teste:
            aux = lista[-1].copy()
            dados[3] = aux[3]
            dados[4] = aux[4]
            dados[5] = aux[5]
            dados[6] = aux[6]
            dados[7] = aux[7]

        df_teste = pd.DataFrame(dados_teste, columns=df.columns)

        df = pd.concat([df, df_teste]).reset_index(drop=True)
        print(df.tail(6))
        # ===============================================
        # Inserir dados de teste (financeiro) => Fim
        # ===============================================

        st.write(f"{df.shape[0]} clientes selecionados")

        st.dataframe(
            df,
            hide_index=True,
            width=760,
            height=250,
        )

        # # =================================
        # # !Enviar dados de teste - 1 linha
        # # =================================
        # df = df.tail(3).copy()

        if len(options) == 0:
            st.sidebar.warning("Nenhuma opção foi selecionada!", icon="⚠️")
        if "Exportar arquivo CSV" in options:
            ctr.exporta_zenvia(df)
        if "Enviar e-mails" in options:
            ctr.send_email(email_origem, df)

    st.success("Finailizado com sucesso!")

st.sidebar.write("-------------------------------------------------------------------")

# * ###############################################################################################################
# * Configuração de design da página
# * ###############################################################################################################
# Ajusta o padding do topo da página
# Ajusta o padding da sidebar
# Cria e ajusta um rodapé
st.markdown(
    """
        <style>
               .block-container {
                    padding-top: 2rem;
                    padding-bottom: 0rem;
                    padding-left: 0rem;
                    padding-right: 2rem;
                }

                .st-emotion-cache-10oheav {
                    padding: 2rem 1rem;
                }

                .footer {
                    position: fixed;
                    left: 0;
                    bottom: 0;
                    width: 100%;
                    background-color: white;
                    color: grey;
                    text-align: center;
                }
        </style>
    """,
    unsafe_allow_html=True,
)
FOOTER = """    <div class="footer">
                    <p>© 2024 ADT Smart Security. All rights reserved. - Desenvolvido por Almir Martins Lopes</p>
                </div>
        """
st.markdown(FOOTER, unsafe_allow_html=True)
# * ###############################################################################################################
# * Fim da Configuração de design da página
# * ###############################################################################################################
