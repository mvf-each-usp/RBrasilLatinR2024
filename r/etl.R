# lib
library(lubridate)
library(magrittr)
library(ggplot2)
library(tidyverse)
library(tidytext)
####$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#### Read exported messages of Telegram  ##############
####$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
parser_telegram <- function(html_file) {
  # pega todas as mensagens
  divs <- xml2::read_html(html_file) %>%
    xml2::xml_find_all("//div[@class='message default clearfix']")
  # nome da pessoa
  nomes <- divs %>%
    xml2::xml_find_all("./div/div[@class='from_name']") %>%
    xml2::xml_text() %>%
    stringr::str_squish()
  # data e hora da mensagem
  data_horas <- divs %>%
    xml2::xml_find_all("./div/div[@class='pull_right date details']") %>%
    xml2::xml_attr("title") %>%
    lubridate::dmy_hms()
  # texto da mensagem
  textos <- divs %>%
    purrr::map(xml2::xml_find_first, "./div/div[@class='text']") %>%
    purrr::map_chr(xml2::xml_text) %>%
    stringr::str_squish()
  # retorna numa tabela
  tibble::tibble(
    data_hora = data_horas,
    nome = nomes,
    texto = textos
  )
}

## path (deletei os dados para nao ocupar mem do github)
path <- "./raw/ChatExport_2024-08-18/"

### list de arquivos com as msgs
messages <- fs::dir_ls(path, regexp = "messages")

### df 05-01-2021
df <- purrr::map_dfr(
  messages,
  parser_telegram,
  .id = "arquivo")
########## rds
saveRDS("df", file = "./data/df.rds")
