library("RMySQL")
# library(tidyverse)
library(dplyr)

# Functions
dbDisconnectAll <- function(){
  ile <- length(dbListConnections(MySQL())  )
  lapply( dbListConnections(MySQL()), function(x) dbDisconnect(x) )
  cat(sprintf("%s connection(s) closed.\n", ile))
}

# General SQL query
query <- function(q)
{
  # Remote DB with password
  con <- dbConnect(MySQL(), 
                   user  = "guest",
                   password    = "guest",
                   dbname="meadows",
                   port = 3306,
                   host   = "sxouse.ddns.net")
  rs1 = dbSendQuery(con, q)
  return(as_tibble(fetch(rs1, n=-1)))
  dbDisconnectAll()
}

# Load the database
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
  
  
  q <- sprintf('select assembly_id, assembly_name, quadrat_count, community, quadrat_id, quadrat_size, visit_date, records_id, species.species_id, 
    species.species_name from assemblies
      join quadrats on quadrats.assembly_id = assemblies_id
      join visit_dates on quadrats.vd_id = visit_dates.vds_id
      join records on records.quadrat_id = quadrats_id
      join species on species.species_id = records.species_id
      # Two assemblies have 0 quadrat count; exclude A.capillaris_stolonifera;
      # exclude some odd assemblies with no assigned community
    where quadrat_count = 5 and species.species_id != 4 and community is not null
    and quadrat_size = "2x2";') 
  # NOTE: this extract includes "MG5", i.e. some MG5 communities where 
  # the team have not decided
  # on a sub-group.
  
  rs1 = dbSendQuery(con, q)
  return(as_tibble(fetch(rs1, n=-1)))
  dbDisconnectAll()
}

SetOne <- function(x, na.rm = T) (1)

the_data <- GetTheData()
# Make quadrat based occupancy matrix d1
d1 <- (the_data %>% select(quadrat_id, species_name) 
       %>% group_by(quadrat_id, species_name) 
       %>% summarise(n=n())
       # species_name by row, quadrat_id by column
       %>% pivot_wider(names_from = quadrat_id, values_from = n)
       %>% replace(., is.na(.), 0)) # Replace NAs with 0

# Make the stand (assembly) based occupancy matrix d2
d2 <- (the_data %>% select(assembly_id, species_name)
       %>% group_by(assembly_id, species_name)
       %>% summarise(n=n())
       %>% ungroup()
       # species_name by row, assembly_id by column
       %>% pivot_wider(names_from = assembly_id, values_from = n))
# At this point, d2 has the number of hits for each assembly and species.
# Replace anything numeric with 1, and any NA with 0
d3 <- (d2 %>% select(-species_name) %>% replace(., !is.na(.), 1)
       %>% replace(., is.na(.), 0)) # Replace NAs with 0)
d3 <- bind_cols(select(d2, species_name), d3)
# Rename and delete d3
d2 <- d3
rm(d3)

# write.csv(d1, "site_occupancy_quadrats")
# write.csv(d2, "site_occupancy_stands")
