source("db_extract.R")

# Reduced version of the_data excluding Mires, i.e. only mesotrophic grassland
the_data <- GetTheData() %>% filter(grepl("MG", community))

# q <- "SELECT community, species_id, p_central FROM meadows.mg_rodwell where community like 'MG%';"
# std_freqs <- query(q)

SpeciesFreqWithStandard <- function(t_d, spn)
{
  q <- "SELECT community, species_id, p_central FROM meadows.mg_rodwell where community like 'MG%';"
  std_freqs <- query(q)
  
  q <- paste('SELECT species_name, species_id FROM meadows.species where species_name = "',spn, '";', sep = "")  
  s <- query(q)
  stdf <- std_freqs %>% filter(species_id == s$species_id)
  d <- (FrequencyByAssembly(t_d) 
        %>% filter(species_name == spn) 
        %>% select(assembly_id, assembly_name, community, freq, CrI5, median, CrI95))
  d1 <- left_join(d, stdf, by = "community")
  d2 <- replace_na(d1, list(p_central=0)) %>% select(-species_id)

  return(d2)
}
  