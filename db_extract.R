#     db_extract.R extracts data from the River Ouse Project meadows database
#     Copyright (C) 2019  J. B. Pilkington j.b.pilkington@gmail.com
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

GrossFrequency <- function(d) 
{
  # Gross frequency for each species.
  # Need hits and trials (quadrats)
  species_freq <- d %>% group_by(species_id, species_name) %>% summarise(hits = n())
  trials <- n_distinct(d$quadrat_id)
  return(species_freq %>% mutate(trials)
                   %>% mutate(freq = hits/trials)
                   %>%  mutate(CrI5 = qbeta(0.05, hits+1, 1+trials-hits))
                   %>%  mutate(median = qbeta(0.5, hits+1, 1+trials-hits)) # For comparison with frequency as hits/trials
                   %>%  mutate(CrI95 = qbeta(0.95, hits+1, 1+trials-hits))
  )
}

FrequencyByCommunity <- function(d)
{
  # Species frequencies by community
  # Need trials for each community
  trials_by_community <- d %>% group_by(nvc) %>% summarise(trials = n_distinct(quadrat_id))
  # Need hits for each community and species
  hits_by_community <- d %>% group_by(nvc, species_name, species_id) %>% summarise(hits = n_distinct(records_id))
  return(left_join(hits_by_community, trials_by_community, by = "nvc")
                        %>%  mutate(freq = hits/trials)
                        %>%  mutate(CrI5 = qbeta(0.05, hits+1, 1+trials-hits))
                        %>%  mutate(median = qbeta(0.5, hits+1, 1+trials-hits)) # For comparison with frequency as hits/trials
                        %>%  mutate(CrI95 = qbeta(0.95, hits+1, 1+trials-hits)))
}

FrequencyByAssembly <- function(d)
{
  # Species frequencies by assembly
  # Need trials for each assembly
  trials_by_assembly <- the_data %>% group_by(assembly_id, assembly_name) %>% summarise(trials = n_distinct(quadrat_id))
  # Need hits for each assembly and species
  hits_by_assembly <- the_data %>% group_by(assembly_id, species_name, species_id) %>% summarise(hits = n_distinct(records_id))
  freq_by_assembly <- (left_join(hits_by_assembly, trials_by_assembly, by = "assembly_id")
                       %>%  mutate(freq = hits/trials)
                       %>%  mutate(CrI5 = qbeta(0.05, hits+1, 1+trials-hits))
                       %>%  mutate(median = qbeta(0.5, hits+1, 1+trials-hits)) # For comparison with frequency as hits/trials
                       %>%  mutate(CrI95 = qbeta(0.95, hits+1, 1+trials-hits))
  )
  # Reorder the columns to put assembly_name next to assembly_id
  return(freq_by_assembly %>% select(assembly_id, assembly_name, species_id, species_name, hits, trials, freq, CrI5, median, CrI95))
}

CommunitySpeciesCounts <- function(freq_by_community)
{
  #  Species counts by community
  return(freq_by_community %>% group_by(nvc) %>% summarise(species_count = n_distinct(species_id)))
}

AssemblySpeciesCounts <- function(freq_by_assembly)
{
  return(freq_by_assembly %>% group_by(assembly_id, assembly_name) %>% summarise(species_count = n_distinct(species_id)))
}


########################## MAIN ##############################
# GET DATA FROM DB
the_data <- GetTheData()

# In Shiny: don't just pass the_data but pass a selection, e.g. community, year, species.
species_freq <-  GrossFrequency(the_data)
freq_by_community <- FrequencyByCommunity(the_data)
freq_by_assembly <- FrequencyByAssembly(the_data)
#  Species counts by community
community_species_counts <- CommunitySpeciesCounts(freq_by_community)
# and by assembly
assembly_species_counts <- AssemblySpeciesCounts(freq_by_assembly)

