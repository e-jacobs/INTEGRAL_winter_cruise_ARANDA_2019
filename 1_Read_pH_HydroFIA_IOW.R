# Packages ----------------------------------------------------------------

library(tidyverse)
library(lubridate)
library(here)


# Read HydroFIA pH data postprocessed according to Mueller and Reh --------

HF1 <- read_csv(here::here("Data/pH_HydroFIA_IOW/PH-0218-001", "2019-03-08-18-06-18-pH-recalculated.csv")) %>% 
  mutate(instrument = "1_PH-0218-001")

HF3 <- read_csv(here::here("Data/pH_HydroFIA_IOW/PH-1017-001", "2019-03-08-18-11-08-pH-recalculated.csv")) %>% 
  mutate(instrument = "3_PH-1017-001")

HF <- bind_rows(HF1, HF3)
rm(HF1, HF3)


HF <-
  HF %>% 
  select(date_time = "timeStamp","sampleName",sal="salinity", tem_measure = "temperature", 
         pHT_25="ph_mueller",pHError="ph_mueller_error", "instrument") %>% 
  filter(date_time > ymd_h("2019-02-28T12"))



# Subset data from continous surface water measurements -------------------

HF.SW <-
HF %>% 
  filter(sampleName == "SW")



# Subset data from discrete profile samples -------------------------------

HF.discrete <-
HF %>%  
  mutate(station = str_sub(sampleName,1,4),
         dep = as.numeric(str_sub(sampleName,5,7))) %>% 
  filter( !( station %in% c("SW","JUNK","CRMY","TRIS") ) )
  



# HF <-
#   HF %>% 
#   mutate(AT = (salinity/35)*2300e-6,
#          pH.Mueller.25 = pHinsi(pH = pH, ALK = AT, Tinsi = 25, Tlab = temperatureSample))


# Plot results and cleaning of errorneous measurements --------------------

HF.SW %>% 
  #filter(pH>7.55) %>% 
  ggplot()+
  geom_path(aes(date.time, pH, col=instrument))+
  scale_x_datetime(date_labels = "%d.%b, %H:%M")+
  scale_color_brewer(palette = "Set1", name="Instrument")+
  labs(x="Date", y="pHT @ 25oC")+
  theme_bw()


HF.SW <-
  HF.SW %>% 
  filter(pH<7.8)


HF.discrete %>% 
  ggplot()+
  geom_point(aes(pH, dep, col=instrument))+
  scale_color_brewer(palette = "Set1", name="Instrument")+
  scale_y_reverse()+
  facet_wrap(~station)+
  theme_bw()

HF.discrete <-
  HF.discrete %>% 
  group_by(station, dep) %>% 
  slice(tail(row_number(), 3)) %>%  
  ungroup() %>% 
  filter(!(pH == 7.295 & station == "LL12")) %>% 
  filter(!(station %in% c("OUL3","OUL4","JUNK","TRIS","BOX-")))



write_csv(HF, here("Data/_summarized_data", "HydroFIA_pH_all_INTEGRAL_winter.csv"))
write_csv(HF.SW, here("Data/_summarized_data", "HydroFIA_pH_SW_INTEGRAL_winter.csv"))
write_csv(HF.discrete, here("Data/_summarized_data", "HydroFIA_pH_discrete_INTEGRAL_winter.csv"))