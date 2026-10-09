

#########################
# Examples / Tests
#########################

## Example 1: simple boxplot
p1 <- ggplot(mpg, aes(drv, hwy)) +
  geom_hline(yintercept = 28, colour = "red") +
  geom_boxplot()
p1
optimal_graph(p1)
p  <- p1
pg <- ggplot_build(p)
d  <- pg$plot$data
## Example 2: colour + facet
p2 <- ggplot(mpg, aes(drv, hwy, colour = class)) +
  geom_boxplot() +
  facet_wrap(~ year)
p2
optimal_graph(p2, detail = TRUE, pooled = FALSE)
optimal_graph(p2, detail = TRUE, pooled = TRUE)
optimal_graph(p2, detail = TRUE, pooled = TRUE, layout = "original", error_bar = "ci95_dif")
optimal_graph(p2, detail = TRUE, pooled = TRUE, layout = "summary", error_bar = "ci95_dif")
optimal_graph(p2, detail = TRUE, pooled = FALSE, layout = "summary", error_bar = "ci95_dif")
optimal_graph(p2, output = "y_axis_limit")
## Build some 2-level factors for mpg
mpg_df <- mpg |>
  mutate(
    drv2        = forcats::fct_other(drv, keep = c("4", "f")),
    year_f      = factor(year),
    class_small = ifelse(class %in% c("subcompact", "compact"), "small", "other"),
    class_small = factor(class_small)
  ) |>
  filter(!is.na(drv2), !is.na(class_small)) |>
  droplevels()

## Example 3: 2-level x
p3 <- ggplot(mpg_df, aes(drv2, hwy)) +
  geom_boxplot()
p3
optimal_graph(p3)

## Example 4: 2-level x + facet
p4 <- ggplot(mpg_df, aes(drv2, hwy)) +
  geom_boxplot() +
  facet_wrap(~ year_f)
p4
optimal_graph(p4)

## Example 5: 2 IVs – x and colour
p5 <- ggplot(mpg_df, aes(drv2, hwy, colour = class_small)) +
  geom_boxplot()
p5
optimal_graph(p5)

## Example 6: 3 IVs – x, colour, facet
p6 <- ggplot(mpg_df, aes(drv2, hwy, colour = class_small)) +
  geom_boxplot() +
  facet_wrap(~ year_f)
p6
optimal_graph(p6)

## Example 7: aggregated means (tests pooled-SD robustness)
mpg_means <- mpg_df |>
  group_by(class_small, drv2) |>
  summarise(hwy = mean(hwy), .groups = "drop")

p7 <- ggplot(mpg_means, aes(class_small, hwy, fill = drv2)) +
  geom_col(position = "dodge")
p7
optimal_graph(p7)

## Example 8: line plot with 2-level x and colour
mpg_year_drv <- mpg_df |>
  group_by(year_f, drv2) |>
  summarise(hwy = mean(hwy), .groups = "drop")

p8 <- ggplot(mpg_year_drv, aes(year_f, hwy, colour = drv2, group = drv2)) +
  geom_line() +
  geom_point()
p8
optimal_graph(p8, layout = "original")

## Example 9: ToothGrowth – 2-level x
tg <- ToothGrowth |>
  filter(dose %in% c(0.5, 2.0)) |>
  droplevels()

p9 <- ggplot(tg, aes(supp, len)) +
  geom_boxplot()
p9
optimal_graph(p9)

## Example 10: ToothGrowth – facet
tg2 <- ToothGrowth |>
  mutate(
    dose2 = ifelse(dose <= 0.7, "low", "high"),
    dose2 = factor(dose2)
  ) |>
  droplevels()

p10 <- ggplot(tg2, aes(supp, len)) +
  geom_boxplot() +
  facet_wrap(~ dose2)
p10
optimal_graph(p10)

## Example 11: ToothGrowth – colour
p11 <- ggplot(tg2, aes(supp, len, colour = dose2)) +
  geom_boxplot()
p11
optimal_graph(p11)

## Example 12: PlantGrowth – 2-level treatment factor
pg <- PlantGrowth |>
  mutate(
    group2 = ifelse(group == "ctrl", "ctrl", "trt"),
    group2 = factor(group2)
  ) |>
  droplevels()

p12 <- ggplot(pg, aes(group2, weight)) +
  geom_boxplot()
p12
optimal_graph(p12, measurement_range = c(1,7))

## Example 13: PlantGrowth – facet on weight bin
pg2 <- pg |>
  mutate(
    wt_bin = ifelse(weight < median(weight), "low", "high"),
    wt_bin = factor(wt_bin)
  )

p13 <- ggplot(pg2, aes(group2, weight)) +
  geom_boxplot() +
  facet_wrap(~ wt_bin)
p13
optimal_graph(p13)

## Example 14: mpg – shape aesthetic as IV
mpg_shape <- mpg_df |>
  mutate(
    cyl2 = ifelse(cyl <= 4, "small", "big"),
    cyl2 = factor(cyl2)
  )

p14 <- ggplot(mpg_shape, aes(drv2, hwy, shape = cyl2)) +
  geom_point(position = position_jitter(width = 0.2), alpha = 0.6)
optimal_graph(p14)


############# p15
set.seed(123)
dat_2x3 <- expand.grid(
  Group = factor(c("A", "B")),
  Condition = factor(paste0("C", 1:3)),
  id = 1:40
) |>
  mutate(
    mu = case_when(
      Group == "A" & Condition == "C1" ~ 0,
      Group == "A" & Condition == "C2" ~ 0.3,
      Group == "A" & Condition == "C3" ~ 0.6,
      Group == "B" & Condition == "C1" ~ 0.2,
      Group == "B" & Condition == "C2" ~ 0.7,
      Group == "B" & Condition == "C3" ~ 1.0
    ),
    DV = rnorm(n(), mean = mu, sd = 0.4)
  )

# helper: mean ± 95% CI
mean_ci95 <- function(x, na.rm = TRUE) {
  x <- x[!is.na(x)]
  n  <- length(x)
  m  <- mean(x)
  se <- stats::sd(x) / sqrt(n)
  ci <- stats::qt(0.975, df = n - 1) * se
  c(y = m, ymin = m - ci, ymax = m + ci)
}

p_2x3_A <- ggplot(dat_2x3, aes(Condition, DV, colour = Group, group = Group)) +
  stat_summary(fun = mean,
               geom = "point",
               position = position_dodge(width = 0.3)) +
  stat_summary(fun.data = mean_ci95,
               geom = "errorbar",
               position = position_dodge(width = 0.3),
               width = 0.2)

p_2x3_A
optimal_graph(p_2x3_A, detail = TRUE)



##################p16
set.seed(456)
dat_2x3 <- expand.grid(
  Group = factor(c("A", "B")),
  Condition = factor(paste0("C", 1:3)),
  id = 1:40
) |>
  mutate(
    mu = case_when(
      Group == "A" & Condition == "C1" ~ 0,
      Group == "A" & Condition == "C2" ~ 0.3,
      Group == "A" & Condition == "C3" ~ 0.6,
      Group == "B" & Condition == "C1" ~ 0.2,
      Group == "B" & Condition == "C2" ~ 0.7,
      Group == "B" & Condition == "C3" ~ 1.0
    ),
    DV = rnorm(n(), mean = mu, sd = 0.8)  # a bit noisier
  )

p_rain <- ggplot(dat_2x3, aes(Condition, DV, fill = Group)) +
  geom_violin(width = 0.8, alpha = 0.3, position = position_dodge(width = 0.8)) +
  geom_boxplot(width = 0.15, position = position_dodge(width = 0.8), outlier.shape = NA) +
  geom_jitter(position = position_jitterdodge(jitter.width = 0.1, dodge.width = 0.8),
              alpha = 0.4, size = 1)

p_rain 
optimal_graph(p_rain, detail = TRUE, layout = "summary")
optimal_graph(p_rain, detail = TRUE, layout = "original")


## to have a correct summary table
p_for_summary <- p_rain + aes(colour = Group)
result <- optimal_graph(
  p_for_summary,
  detail = TRUE,
  layout = "summary"
)

result$plot

################# p17
### visulization
library(readr)
Study4_long <- read_csv("Study4_long.csv")
Study4B_long <- Study4_long
## boxplot (sequence of x-axis)
boxplot <- Study4B_long%>%
  ggplot(aes(x= EB, y= `average_rating`, color=distortion))+
  geom_boxplot()+
  facet_grid(rows=vars(format))+
  ylim(1,7)+
  scale_colour_manual('distortion',values=c('blue','purple')) + 
  ggtitle('box plot')+
  theme_bw()+ 
  scale_x_discrete(labels=c("no EB","small EB","medium EB", "large EB"))
boxplot 
optimal_graph(boxplot)
optimal_graph(boxplot, layout = "original")
optimal_graph(data = Study4_long, within  =c("EB", "distortion"),DV= c("average_rating"),id="id", detail = TRUE, error_bar = "ci95_corr", layout = "original")
optimal_graph(data = Study4_long, between  =c("EB", "distortion"),DV= c("average_rating"), detail = TRUE)

optimal_graph(plot=boxplot,   data = Study4_long, within  =c("EB", "distortion"),DV= c("average_rating"),id="id", detail = TRUE, error_bar = "ci95_corr", layout = "original")
optimal_graph(plot=boxplot,   data = Study4_long, within  =c("EB", "distortion"),DV= c("average_rating"),id="id", output = "y_axis_limit")
optimal_graph(plot=boxplot,   data = Study4_long, within  =c("EB", "distortion"),DV= c("average_rating"),id="id",error_bar = "ci95_corr", output = "y_axis_limit")
###################### superb p18
###violplot
head(Study4B_long)
ornate <- list(
  scale_color_manual( name = "Distortion", labels = c("no truncation", "lower truncation"), values = c("blue", "purple")),
  scale_fill_manual( name = "Distortion", labels =  c("no truncation", "lower truncation"), values = c("blue", "purple")),
  scale_shape_manual( name = "Distortion", labels = c("no truncation", "lower truncation"), values = c(16,17)),
  xlab("Error bar"),
  ylab("Average ratings"),
  scale_x_discrete(labels=c("no error bar","small error bar","medium error bar", "large error bar"))
)

###meantale
library(superb)
meanplot <- superb(average_rating~EB|id+distortion|id,
                   Study4B_long,
                   statistic = "meanNArm",
                   adjustments = list(purpose = "difference", decorrelation = "CA"),
                   plotStyle = "line"
)+ theme_bw()+
  ylim(1,7)+
  ornate+
  scale_y_continuous( expand = expansion(mult = c(0, 0)),limits = c(1,7),breaks = c(1:7))+
  theme(legend.position = c(0.1,0.9))

meanplot


optimal_graph(meanplot, layout = "original",error_bar = "ci95_dif",)
optimal_graph(data = Study4_long, within  =c("EB", "distortion"),DV= c("average_rating"),plot = meanplot, id = "id",detail = TRUE, error_bar = "ci95_corr", layout = "original")
optimal_graph(data = Study4_long, between  =c("EB", "distortion"),DV= c("average_rating"), detail = TRUE)



### violin ############### superb p19
Study4B_violplot <- superb(average_rating~EB|id+distortion|id,
                           Study4B_long,
                           statistic = "mean",
                           adjustments = list(purpose = "difference", decorrelation = "CA"),
                           plotStyle = "raincloud",
                           errorbarParams = list(alpha = 1, width = 0.15, size = 0.3,color = "black"), #width for error bar width
                           jitterParams  = list(alpha = 0.5, width=0.025,size = 0.25),#alpha for brightness. size for the size
                           pointParams = list(alpha = 1, size = 2.5), # mean same
                           violinParams = list( push=0.) ### ANTAGONIZE HERE
) +theme_bw()+
  #ylim(1,7)+
  ornate+
  scale_y_continuous( expand = expansion(mult = c(0, 0)),limits = c(1,7),breaks = c(1:7))+
  theme(legend.position = c(0.1,0.85))
Study4B_violplot
optimal_graph(Study4B_violplot)
optimal_graph(Study4B_violplot, layout = "original")
optimal_graph(data = Study4B_long, within  =c("EB", "distortion"),DV= c("average_rating"), id = "id",detail = TRUE, error_bar = "ci95_corr", layout = "original")
optimal_graph(data = Study4B_long, between  =c("EB", "distortion"),DV= c("average_rating"), detail = TRUE)

optimal_graph(data = Study4B_long, within  =c("EB", "distortion"),DV= c("average_rating"), id = "id",detail = TRUE, error_bar = "ci95_corr", layout = "original",output = "y_axis_limit")
optimal_graph(data = Study4B_long, within  =c("EB", "distortion"),DV= c("average_rating"), pooled = FALSE, id = "id",detail = TRUE, error_bar = "ci95_corr", layout = "original",output = "y_axis_limit")

optimal_graph(data = Study4B_long, between  =c("EB", "distortion"),DV= c("average_rating"), detail = TRUE)

######## issues of superb vs ggplot2
p  <- Study4B_violplot
pg <- ggplot_build(p)
d  <- pg$plot$data
design_info <- extract_design_from_pg(pg)
dv_from_plot <- design_info$DV


