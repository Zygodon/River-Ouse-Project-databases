# Get quadrat-based species frequencies for assemblies, on selected species and communities
# Libraries
library("RMySQL")
library(tidyverse)

# Functions
dbDisconnectAll <- function(){
  ile <- length(dbListConnections(MySQL())  )
  lapply( dbListConnections(MySQL()), function(x) dbDisconnect(x) )
  cat(sprintf("%s connection(s) closed.\n", ile))
}

GetTheData <-  function()
{
  # GET DATA FROM DB
  # Remote DB with password - works Ok but table mg_standards6 is not available on PI. Should update.
  con <- dbConnect(MySQL(), 
                   user  = "guest",
                   password    = "guest",
                   dbname="meadows",
                   port = 3306,
                   host   = "sxouse.ddns.net")
  
  
  q <- sprintf('select assembly_id, assembly_name, quadrat_count, nvc, quadrat_id, visit_date, records_id, species.species_id, 
    species.species_name from assemblies
      join quadrats on quadrats.assembly_id = assemblies_id
      join visit_dates on quadrats.vd_id = visit_dates.vds_id
      join records on records.quadrat_id = quadrats_id
      join species on species.species_id = records.species_id
    # Two assemblies have 0 quadrat count; exclude A.capillaris_stolonifera; exclude 
    # some odd assemblies with no assigned nvc
    where quadrat_count > 0 and species.species_id != 4 and nvc is not null;') 
  # NOTE: this extract includes "MG5", i.e. some MG5 communities where the team have not decided
  # on a sub-group.
  
  rs1 = dbSendQuery(con, q)
  return(as_tibble(fetch(rs1, n=-1)))
  dbDisconnectAll()
}

############## MAIN ##############
# Define species to use
spp <- c(168, 35, 36, 182, 43, 188, 44, 58, 195, 84, 88, 89, 208, 139, 148, 346)

the_data <- GetTheData()
d <- (the_data %>% select(assembly_id, nvc, species_id, species_name)
      # %>% filter(nvc %in% c("MG5a", "MG5c"))
      # %>% filter(species_id %in% spp)
      )

species_hits <- (d %>% group_by(assembly_id, species_name) 
                  %>% summarise(hits = n()))

t <- (the_data %>% select(assembly_id, quadrat_id)
           %>% group_by(assembly_id)
           %>% summarise(trials = n_distinct(quadrat_id)))

species_freq <- (left_join(species_hits, t, by = "assembly_id")
                %>% mutate(freq = hits/trials)
                %>% mutate(freq = sprintf("%0.2f", freq)))

nvcs <- the_data %>% select(assembly_id, nvc) %>% distinct()
data <- (left_join(species_freq, nvcs, by = "assembly_id") 
         %>% select(assembly_id, nvc, species_name, hits, trials, freq))


# data <- (left_join (species_freq, sites, by = c("assembly_id" = "assemblies_id"))
#          %>% ungroup() 
#          %>% select(site_name, meadow_name, assembly_name, nvc, species_name, hits, trials, freq))
# 
# write.csv(data, "MG5 data.csv")
