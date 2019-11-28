
# Boxplot: species counts for communities aggregated over assemblies;
# communities with fewer than 4 examples excluded.

source ("db_extract.R")

# NVC standard species counts for comparison
stds <- tribble(
  ~nvc, ~std_cnts,
  "M10b",   37,
  "M23",   19,
  "M23a",   21,
  "M23b",   17,
  "M27b",   14,
  "M27c",   15,
  "M28b",   20,
  "MG10",   13,
  "MG10a",   12,
  "MG10b",   15,
  "MG13",   8,
  "MG1b",   12,
  "MG1c",   15,
  "MG1e",   21,
  "MG5",   23,
  "MG5a",   22,
  "MG5c",   22,
  "MG6a",   13,
  "MG6b",   14,
  "MG7b",   8,
  "MG7c",   11,
  "MG7d",   9,
  "MG8",   26,
  "MG9a",   15
)


# Count the number of assemblies in each community
# If there are only one or two, we won't want to include 
# that community in the boxplot
a <- (the_data 
      %>% select(assembly_id, nvc)
      %>% group_by(nvc) 
      %>% summarise(nvc_cnt = n_distinct(assembly_id)))

# Count the number of species at each survey site (assembly)
# This is what we are interested in making a boxplot for.
d <- (the_data %>% select(assembly_id, nvc, species_name)
               %>% group_by(assembly_id, nvc) 
               %>% summarise(sp_cnt = n_distinct(species_name)))

# Left join and filter out communities with less than 4 examples
d <- left_join(d, a, by = "nvc") 
d <- left_join(d, stds, by = "nvc") %>% filter(nvc_cnt > 3)

# Prepare xlab with the number of assemblies for each community
ns <- d %>% group_by(nvc) %>% distinct(nvc_cnt) %>% arrange(nvc)
x_labels <- paste(levels(as.factor(d$nvc)),"\n(n=",ns$nvc_cnt,")",sep="")

# Make the plot
g <- ggplot(d, aes(nvc,sp_cnt)) +
  coord_cartesian(ylim = c(0, 80)) +
  geom_boxplot(varwidth = T) +
  geom_point(y = d$std_cnts, colour = "red") +
  theme(legend.position = "none") +
  xlab("Assessed NVC community") +
  ylab("species count by assembly") +
  scale_x_discrete(labels = tolower(x_labels))
print(g)


