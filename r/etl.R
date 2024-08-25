# carregando as bibliotecas ----
library(tidyverse)
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

# parse das mensagens para data frame ----
df1 <-
  tibble(
    id = xml_attr(mensagens, "id"),
    classe = xml_attr(mensagens, "class"),
    autor =
      mensagens |>
      xml_find_first(".//div[@class='from_name']") |>
      xml_text() |>
      str_squish(),
    data =
      mensagens |>
      xml_find_first(".//div[@class='pull_right date details']") |>
      xml_attr("title") |>
      dmy_hms(),
    texto =
      mensagens |>
      xml_find_first(".//div[@class='text']") |>
      xml_text() |>
      str_squish(),
    reply.to =
      mensagens |>
      xml_find_first(".//div[@class='reply_to details']/a") |>
      xml_attr("href") |>
      str_squish(),
    service.text =
      mensagens |>
      xml_find_first(".//div[@class='body details']") |>
      xml_text() |>
      str_squish(),
    ### O QUE MAIS DEVERIA PEGAR? ----
  )

# savepoint ----
## salvando a versão preliminar para não ter que rerrodar tudo
## saveRDS(df1, "./data/df1.rds")
## df1 <- readRDS("./data/df1.rds") ----

# AQUI!!! ----
## um problema para resolver mais adiante: ----
# a Rose passou a apagar as mensagens de entrada de novo membro;
# isso vai atrapalhar a acompanhar a evolução do número de membros do grupo


# processando as mensagens ----

## confirmando se toda mensagem com id="message-*" é de nova data ----
df1 |>
  filter(str_detect(id, "message-")) |>
  mutate(
    `eh.data?` =
      str_detect(
        service.text,
        paste0(
          "[0-9]{1,2} ",
          "(January|February|March|April|May|June|July|",
          "August|September|October|November|December)",
          " 20[12][0-9]"
        )
      )
  ) |>
  summarise(
    `tudo.data?` = all(`eh.data?`)
  )
### beleza! ----

## incluindo as colunas derivadas das raspadas ----
df2 <-
  df1 |>
  filter(!str_detect(id, "message-")) |> # tirando msg de novo dia
  mutate(
    id = str_extract(id, "[0-9]+$"),
    continuacao = str_detect(classe, "joined"),
    autor = if_else(continuacao, lag(autor), autor), # completando
    resposta = !is.na(reply.to),
    para.qual = reply.to |> str_extract("message([0-9]+)$", group = 1),
    entrou =
      if_else(
        str_detect(service.text, " invited "),
        str_remove(service.text, "^.* invited ") ,
        NA_character_
      ),
    tipo =
      case_when(
        str_detect(classe, "default") ~ "postagem",
        ! is.na(entrou) ~ "entrada",
        .default = "service"
      ),
  ) |>
  select(
    id,
    data,
    tipo,
    autor,
    continuacao,
    resposta,
    para.qual,
    entrou,
    texto,
  )

## confirmando se todas os reply.to estão no mesmo formato ----
df2 |>
  mutate(`certo?` = str_detect(para.qual, "^[0-9]+$")) |>
  summarise(`tudo.certo?` = all(`certo?`, na.rm = TRUE))


## só falta saber para quem foram os replies

df3 <-
  df2 |>
  mutate(
    id = as.integer(id),
    para.qual = as.integer(para.qual),
  )

df4 <-
  left_join(
    df3,
    df3 |>
      filter(tipo == "postagem") |>
      transmute(id, para.quem = autor),
    by = c(para.qual = "id")
  ) |>
  relocate(
    para.quem,
    .after = para.qual
  )

# salvando o data frame com as mensagens ----
saveRDS(df4, "./data/raspagem.rds")

