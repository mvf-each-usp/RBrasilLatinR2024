# remove and clean
rm(list=ls())
gc()
# lib
library(tidyverse)
library(plotly)
library(dplyr)
library(viridis)
### load data

df <- readRDS("./data/df.rds")

# Summarize the data and filter for top 15 users
plot1 <- df |>
  group_by(nome) |>
  summarize(n = n()) |>
  ungroup() |>
  top_n(15, n) |>
  ggplot(aes(x=reorder(nome, -n), y=n, fill=factor(nome))) +
  geom_bar(stat = "identity", color='black', size=0.2) +  # Black border for contrast
  xlab("") +  # Custom label
  ylab("") +
  ggtitle("Top 15 Usuários do Telegram R-Brasil por Total de Mensagens") +
  coord_flip() +
  scale_fill_viridis_d(option = "viridis") +  # Apply the viridis color palette
  theme_void(base_size = 15) +  # Clean theme with increased base font size
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 18),  # Center and bold title
    axis.title.x = element_text(face = "bold", size = 14),  # Bold X axis label
    axis.title.y = element_text(face = "bold", size = 14),  # Bold Y axis label
    axis.text.x = element_text(size = 12),  # Size of X axis text
    axis.text.y = element_text(size = 12),  # Size of Y axis text
    panel.grid.major.y = element_blank(),  # Remove major gridlines on Y axis
    panel.grid.minor.y = element_blank(),  # Remove minor gridlines on Y axis
    panel.grid.major.x = element_line(color = "gray", size = 0.5),  # Light gridlines on X axis
    legend.position = "none"  # Hide legend to focus on bar colors
  )

# Convert the ggplot to a Plotly plot
plotly_plot <- ggplotly(plot1)

# Display the Plotly plot
plotly_plot


## Total de mensagens ao longo do tempo

plot2 <- df %>%
  dplyr::mutate(mes = lubridate::floor_date(data_hora, "month")) %>%
  dplyr::count(mes) %>%
  ggplot(aes(x = mes, y = n)) +
  geom_line(color = "darkblue", size = 1) +  # Line color and thickness
  geom_point(color = "darkred", size = 3) +  # Point color and size
  xlab("") +
  ylab("") +
  ggtitle("Total de mensagens no Telegram do R-Brasil") +
  theme_gray(base_size = 16)  # Apply the gray theme with a base font size

# Convert the ggplot to a Plotly plot
plotly_plot2 <- ggplotly(plot2)

# Display the Plotly plot
plotly_plot2

### total de mensagens por user ao longo do tempo
df %>%
  dplyr::filter(nome != "Deleted Account") %>%
  dplyr::mutate(nome = forcats::fct_lump(nome, 12),
                nome = as.character(nome),
                mes = lubridate::floor_date(data_hora, "month")) %>%
  dplyr::filter(nome != "Other") %>%
  dplyr::count(mes, nome, sort = TRUE) %>%
  tidyr::complete(mes, nome, fill = list(n = 0)) %>%
  ggplot(aes(x = mes, y = n)) +
  geom_line() +
  facet_wrap(~nome) +
  labs(x = "Mês", y = "Quantidade de mensagens") +
  ggtitle("Frequência de mensagens por usário no R-Brasil")+
  theme_bw()

## hora que mais interagimos

df %>%
  dplyr::mutate(hora = factor(lubridate::hour(data_hora))) %>%
  ggplot(aes(x = hora)) +
  geom_bar(fill = "royalblue") +
  theme_minimal(14) +
  ylab("Número de Mensagens")+
  ggtitle("Hora das mensagens no Telegram do R-Brasil")


## o dia da semana

df %>%
  dplyr::mutate(wd = lubridate::wday(data_hora, label = TRUE)) %>%
  ggplot(aes(x = wd)) +
  geom_bar(fill = "blue") +
  theme_minimal(14) +
  ylab("Dia da semana")+
  ggtitle("Dia da semana das mensagens")


# dá pra criar funções anônimas assim ;)
# esse é um limpador bem safado que fiz em 1 min
limpar <- . %>%
  abjutils::rm_accent() %>%
  stringr::str_to_title() %>%
  stringr::str_remove_all("[^a-zA-Z0-9 ]") %>%
  stringr::str_remove_all("Pra") %>%
  stringr::str_squish()
library('abjutils')
# tirar palavras que nao quero
banned <- tidytext::get_stopwords("pt") %>%
  dplyr::mutate(palavra = limpar(word))

cores <- viridis::viridis(10, begin = 0, end = 0.8)

df %>%
  tidytext::unnest_tokens(palavra, texto) %>%
  dplyr::mutate(palavra = limpar(palavra)) %>%
  dplyr::anti_join(banned, "palavra") %>%
  dplyr::count(palavra, sort = TRUE) %>%
  with(wordcloud::wordcloud(
    palavra, n, scale = c(5, .1),
    min.freq = 80, random.order = FALSE,
    colors = cores
  ))
