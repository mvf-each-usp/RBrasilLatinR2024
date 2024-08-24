# carregando as bibliotecas ----
library(tidyverse)
# library(tidytext)  # precisa?
library(xml2)

# path dos dados ----
## assim, pega o path certo para qualquer data de exportação
path <-
  fs::dir_ls(
    path = "./data/raw/",
    type = "d",
    regexp = "ChatExport_"
  )
if (length(path) != 1)
  stop("só pode ter um único diretório 'ChatExport_*' dentro de './data'")

# lista de arquivos com as msgs ----
messages <-
  fs::dir_ls(
    path,
    regexp = "messages"
  ) |>
  str_sort(numeric = TRUE)


# salva em .rds ----
saveRDS(df, file = "./data/df.rds")
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
