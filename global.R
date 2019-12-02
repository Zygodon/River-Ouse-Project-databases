source("db_extract.R")

# Reduced version of the_data excluding Mires, i.e. only mesotrophic grassland
the_data <- GetTheData() %>% filter(grepl("MG", community))

q <- "SELECT community, species_id, p_central FROM meadows.mg_rodwell where community like 'MG%';"
std_freqs <- query(q)
