# Boxplot: species counts for communities aggregated over quadrats;
# library("RColorBrewer"): Needed for points overlay on boxplot
source ("db_extract.R")

# NVC standard species counts for comparison
stds <- tribble(
  ~nvc, ~std_cnts, ~low, ~high,
  "M10b",   37, 19, 56,
  "M23",   19, 6, 39,
  "M23a",   21, 6, 39,
  "M23b",   17, 8, 28,
  "M27b",   14, 6, 33,
  "M27c",   15, 9, 22,
  "M28b",   20, 10, 26,
  "MG10",   13, 6, 24,
  "MG10a",   12, 6, 20,
  "MG10b",   15, 8, 24,
  "MG13",   8, 3, 15,
  "MG1b",   12, 3, 18,
  "MG1c",   15, 4, 21,
  "MG1e",   21, 11, 30,
  "MG5",   23, 12, 38,
  "MG5a",   22, 13, 32,
  "MG5c",   22, 18, 27,
  "MG6a",   13, 9, 20,
  "MG6b",   14, 4, 26,
  "MG7b",   8, 4, 14,
  "MG7c",   11, 4, 19,
  "MG7d",   9, 3, 14,
  "MG8",   26, 15, 41,
  "MG9a",   15, 7, 36
)

# Count the number of quadrats of each community
# We may wish to limit the boxplot to communities with
# 5 or more samples (quadrats)
a <- (the_data
      %>% select(quadrat_id, nvc)
      %>% group_by(nvc)
      %>% summarise(nvc_cnt = n_distinct(quadrat_id)))

# Count the number of species in each sample (quadrat)
# This is what we are interested in making a boxplot for.
d <- (the_data %>% select(quadrat_id, nvc, species_name)
      %>% group_by(quadrat_id, nvc) 
      %>% summarise(sp_cnt = n_distinct(species_name)))

# Left join and filter out communities with less than 20 examples
d <- left_join(d, a, by = "nvc") 
d <- left_join(d, stds, by = "nvc") %>% filter(nvc_cnt > 19)
# Add assembly_id for colur coding the data points
assemblies <- the_data %>% select(assembly_id, quadrat_id) %>% group_by(assembly_id) %>% distinct(quadrat_id)
d <- left_join(d, assemblies, by = "quadrat_id")

# Prepare xlab with the number of assemblies for each community
ns <- d %>% group_by(nvc) %>% distinct(nvc_cnt) %>% arrange(nvc)
x_labels <- paste(levels(as.factor(d$nvc)),"\n(n=",ns$nvc_cnt,")",sep="")

# Make the plot
g <- ggplot(d, aes(nvc,sp_cnt)) +
  coord_cartesian(ylim = c(0, 40)) +
  geom_boxplot(varwidth = T, size = 0.5) +
  geom_pointrange(y = d$std_cnts, ymin = d$low, ymax = d$high, shape = 3, colour = "red") +
  theme(legend.position = "none") +
  scale_x_discrete(labels = tolower(x_labels)) +
  xlab("Assessed NVC community") +
  ylab("species count by quadrat")
print(g)

# Plot with points overlaid
# g <- ggplot(d, aes(nvc,sp_cnt)) +
#   coord_cartesian(ylim = c(0, 40)) +
#   geom_boxplot(varwidth = T, size = 0.5, outlier.shape = NA) +
#   geom_jitter(aes(colour = as.factor(assembly_id)), shape = 16, width = 0.2, alpha = 1) +
#   scale_colour_manual(values=rep(brewer.pal(12,"Set3"),times=102)) +
#   theme(legend.position = "none") +
#   scale_x_discrete(labels = tolower(x_labels)) +
#   xlab("Assessed NVC community") +
#   ylab("species count by quadrat")
# print(g)


