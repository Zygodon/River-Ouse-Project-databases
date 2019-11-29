# Get quadrat-based species frequencies for assemblies.
# This is essentially the same as FrequencyByAssembly in db_extract.R
# Version here is possibly more readable
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
  # Remote DB with password
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

the_data <- GetTheData()
d <- the_data %>% select(assembly_id, species_id, species_name)
# Hits for each species in each assembly
species_hits <- (d %>% group_by(assembly_id, species_name) 
                  %>% summarise(hits = n()))
# Trials (quadrats) - quadrat count for each assembly (is indepenedent of species!)
t <- (the_data %>% select(assembly_id, quadrat_id)
           %>% group_by(assembly_id)
           %>% summarise(trials = n_distinct(quadrat_id)))
# Frequency of each species in each assembly, hits/trials
species_freq <- (left_join(species_hits, t, by = "assembly_id")
                %>% mutate(freq = hits/trials)
                %>% mutate(CrI5 = qbeta(0.05, hits+1, 1+trials-hits))
                %>% mutate(median = qbeta(0.5, hits+1, 1+trials-hits)) # For comparison with frequency as hits/trials
                %>% mutate(CrI95 = qbeta(0.95, hits+1, 1+trials-hits)))
# Include community
nvcs <- the_data %>% select(assembly_id, nvc) %>% distinct()
data <- left_join(species_freq, nvcs, by = "assembly_id") 
# Include assembly_name
assemblies <- the_data %>%  select(assembly_id, assembly_name) %>% distinct()
data <- (left_join(data, assemblies, by = "assembly_id")
          %>% select(assembly_id, assembly_name, nvc, species_name, 
              hits, trials, freq, CrI5, median, CrI95)) # reorder

#write.csv(data, "data.csv")
