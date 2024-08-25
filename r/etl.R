# carregando as bibliotecas ----
library(tidyverse)
# library(tidytext)  # precisa?
library(xml2)

# path dos dados ----
## assim, pega o path certo para qualquer data de exportação
dir.raw.data <-
  fs::dir_ls(
    path = "./data/raw/",
    type = "d",
    regexp = "ChatExport_"
  )
if (length(dir.raw.data) != 1)
  stop("só pode ter um único diretório 'ChatExport_*' dentro de './data'")

# carrega tudo e filtra só as mensagens ----
mensagens <-
  fs::dir_ls(dir.raw.data, regexp = "messages") |>
  str_sort(numeric = TRUE) |>
  map(read_html) |>
  reduce(xml_add_sibling) |>
  xml_find_all("//div[contains(@class, 'message')]")

parseia <- function(msgs) {
  tibble(
    id = xml_attr(msgs, "id"),
    classe = xml_attr(msgs, "class"),
    tipo = if_else(str_detect(classe, "service"), "serviço", "postagem"),
    autor =
      msgs |>
      xml_find_first(".//div[@class='from_name']") |>
      xml_text() |>
      str_squish(),
    continuacao = str_detect(classe, "joined"),
    data =
      msgs |>
      xml_find_first(".//div[@class='pull_right date details']") |>
      xml_attr("title") |>
      dmy_hms(),
    texto =
      msgs |>
      xml_find_first(".//div[@class='text']") |>
      xml_text() |>
      str_squish(),
    reply.to =
      msgs |>
      xml_find_first(".//div[@class='reply_to details']/a") |>
      xml_attr("href") |>
      str_squish(),
    entrada =
      msgs |>
      xml_find_first(".//div[@class='body details']") |>
      xml_text() |>
      str_squish(),
    ### O QUE MAIS DEVERIA PEGAR? ----
  ) |>
    select(-classe)
}


tudo[1:50] |>
  parseia()
# a última coluna não pega a mensagem 26 por exemplo,
# que é uma mensagem de entrada no grupo

# um problema para resolver mais adiante:
# a Rose passou a apagar as mensagens de entrada de novo membro;
# isso vai atrapalhar a acompanhar a evolução do número de membros do grupo

mensagens_bruto <-
  parseia(tudo)


# FAZER AQUI ----
# processar direto as mensagens



# mensagens_bruto <- readRDS(file = "./data/mensagens_bruto.rds")
# # função parseadora dos htmls ----
# parser_telegram <- function(html_file) {
#   # indicador de progresso ----
#   cat(html_file |> str_extract("messages([0-9]*\\.)", group = 1))
#   # pega todas as mensagens ----
#   divs <- read_html(html_file) |>
#     xml_find_all("//div[@class='message default clearfix']")
#   # nome da pessoa ----
#   nomes <- divs |>
#     xml_find_all("./div/div[@class='from_name']") |>
#     xml_text() |>
#     str_squish()
#   # data e hora da mensagem ----
#   data_horas <- divs |>
#     xml_find_all("./div/div[@class='pull_right date details']") |>
#     xml_attr("title") |>
#     dmy_hms()
#   # texto da mensagem ----
#   textos <- divs |>
#     map(xml_find_first, "./div/div[@class='text']") |>
#     map_chr(xml_text) |>
#     str_squish()
#   # retorna numa tabela ----
#   tibble(
#     data_hora = data_horas,
#     nome = nomes,
#     texto = textos
#   )
# }
# carrega já parseando todas as mensagens ----
# ## original ----
# df <-
#   {cat("total de", length(mensagens), "arquivos\n")
#     map_dfr(
#       mensagens,
#       parser_telegram,
#       .id = "arquivo"
#     )}
