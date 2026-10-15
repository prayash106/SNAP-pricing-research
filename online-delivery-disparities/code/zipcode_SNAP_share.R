# collect zipcodes for states based on SNAP share
## last edited by: Prayash Pathak
## last edited date: October 15 2026

#load packages
library(tidyverse)
library(tidycensus)
library(censusapi)


acs_year <- 2023

# Pull ZCTA-level SNAP data
#this gives us share of snap households per zipcode
zcta_snap <- get_acs(
  geography = "zcta",
  year = acs_year,
  survey = "acs5",
  variables = c(
    total_hh = "B22010_001",
    snap_hh  = "B22010_002"
  ),
  output = "wide"
) %>%
  transmute(
    zipcode = GEOID,
    year = acs_year,
    total_hh = total_hhE,
    snap_hh = snap_hhE,
    share_snap_hh = snap_hh / total_hh
  ) %>%
  filter(
    !is.na(share_snap_hh),
    total_hh > 0
  )

#####link zipcodes to states#####
library(httr)
library(jsonlite)

hud_key <- "########################"

# Pull ZIP-to-county crosswalk for all states
url <- "https://www.huduser.gov/hudapi/public/usps"

response <- GET(
  url,
  query = list(
    type = 2,       
    query = "All",
    year = 2023,
    quarter = 4
  ),
  add_headers(Authorization = paste("Bearer", hud_key))
)

stop_for_status(response)

output <- content(response, as = "text", encoding = "UTF-8")
hud_json <- fromJSON(output, flatten = TRUE)

hud_results <- as_tibble(hud_json$data$results) %>%
  rename_with(tolower)

zip_state_crosswalk <- hud_results %>%
  transmute(
    zipcode = str_pad(as.character(zip), 5, pad = "0"),
    county_fips = str_pad(as.character(geoid), 5, pad = "0"),
    state = state,
    res_ratio = as.numeric(res_ratio),
    bus_ratio = as.numeric(bus_ratio),
    oth_ratio = as.numeric(oth_ratio),
    tot_ratio = as.numeric(tot_ratio)
  )

#this links zipcode to state
zip_state_crosswalk <- zip_state_crosswalk %>%
  group_by(zipcode) %>%
  slice_max(order_by = res_ratio, n = 1, with_ties = FALSE) %>%
  ungroup()

####now we merge them together####
zcta_snap_state <- zcta_snap %>%
  mutate(zipcode = str_pad(as.character(zipcode), 5, pad = "0")) %>%
  left_join(zip_state_crosswalk, by = "zipcode") %>%
  filter(!is.na(state))

#filter for our selected states of interest
snap_states <- c("ND", "SD", "UT", "MI", "OH", "PA", "FL", "MN") #our seven states

zcta_snap_state_7 <- zcta_snap_state %>%
  filter(state %in% snap_states)

#now we need to clean this up
zcta_snap_state_7 %>%
  group_by(state) %>%
  summarize(
    n_zip = n(),
    mean_hh = mean(total_hh, na.rm = TRUE),
    median_hh = median(total_hh, na.rm = TRUE),
    p10 = quantile(total_hh, .10, na.rm = TRUE),
    p25 = quantile(total_hh, .25, na.rm = TRUE),
    p75 = quantile(total_hh, .75, na.rm = TRUE),
    p90 = quantile(total_hh, .90, na.rm = TRUE),
    max_hh = max(total_hh, na.rm = TRUE)
  )

zcta_snap_state_7 %>%
  ggplot(aes(total_hh, share_snap_hh)) +
  geom_point(alpha = .4) +
  scale_x_log10() +
  facet_wrap(~state)

eligible_zips <- zcta_snap_state_7 %>%
  group_by(state) %>%
  filter(total_hh >= quantile(total_hh, 0.50)) %>%
  ungroup()

high_pool <- eligible_zips %>%
  group_by(state) %>%
  filter(
    share_snap_hh >= quantile(share_snap_hh, .75)
  )
low_pool <- eligible_zips %>%
  group_by(state) %>%
  filter(
    share_snap_hh <= quantile(share_snap_hh, .25)
  )

high_pool %>%
  group_by(state) %>%
  summarize(
    n = n(),
    median_hh = median(total_hh),
    min_hh = min(total_hh),
    max_hh = max(total_hh)
  )

low_pool %>%
  group_by(state) %>%
  summarize(
    n = n(),
    median_hh = median(total_hh),
    min_hh = min(total_hh),
    max_hh = max(total_hh)
  )

bind_rows(
  high_pool %>% mutate(group = "High"),
  low_pool %>% mutate(group = "Low")
) %>%
  group_by(state, group) %>%
  summarize(
    mean_snap = mean(share_snap_hh),
    median_snap = median(share_snap_hh)
  )

# Top 10 high-SNAP ZIPs per state
high_top10 <- high_pool %>%
  arrange(state, desc(share_snap_hh)) %>%
  group_by(state, county_fips) %>%
  slice_head(n = 2) %>%          # max 2 ZIPs per county
  ungroup() %>%
  group_by(state) %>%
  slice_head(n = 10) %>%         
  mutate(group = "High SNAP") %>%
  ungroup()

# Top 10 low-SNAP ZIPs per state
low_top10 <- low_pool %>%
  arrange(state, share_snap_hh) %>%
  group_by(state, county_fips) %>%
  slice_head(n = 2) %>%          # max 2 ZIPs per county
  ungroup() %>%
  group_by(state) %>%
  slice_head(n = 10) %>%         
  mutate(group = "Low SNAP") %>%
  ungroup()

candidate_zips <- bind_rows(high_top10, low_top10)

candidate_zips %>%
  select(
    state,
    zipcode,
    total_hh,
    snap_hh,
    share_snap_hh,
    county_fips,
    group
  ) %>%
  arrange(state, group, desc(share_snap_hh))

candidate_zips %>%
  group_by(state, group) %>%
  summarize(
    mean_snap = mean(share_snap_hh),
    median_snap = median(share_snap_hh),
    median_hh = median(total_hh),
    .groups = "drop"
  )

candidate_zips %>%
  count(state, county_fips, group, sort = TRUE)

candidate_zips <- candidate_zips %>%
  select(-res_ratio, -bus_ratio, -oth_ratio, -tot_ratio)

#write_csv(candidate_zips, "candidate_zips_fresh.csv")

##filter for counties where amazon fresh is available##
amazon_fresh_counties <- tribble(
  ~market, ~state, ~county_fips,
  
  # Minnesota
  "Minneapolis-St Paul", "MN", "27053", # Hennepin
  "Minneapolis-St Paul", "MN", "27123", # Ramsey
  "Minneapolis-St Paul", "MN", "27037", # Dakota
  "Minneapolis-St Paul", "MN", "27003", # Anoka
  "Minneapolis-St Paul", "MN", "27163", # Washington
  "Minneapolis-St Paul", "MN", "27139", # Scott
  "Minneapolis-St Paul", "MN", "27019", # Carver
  
  # Illinois
  "Chicago", "IL", "17031", # Cook
  "Chicago", "IL", "17043", # DuPage
  "Chicago", "IL", "17089", # Kane
  "Chicago", "IL", "17097", # Lake
  "Chicago", "IL", "17197", # Will
  "Chicago", "IL", "17111", # McHenry
  
  # Michigan
  "Detroit", "MI", "26163", # Wayne
  "Detroit", "MI", "26125", # Oakland
  "Detroit", "MI", "26099", # Macomb
  "Ann Arbor", "MI", "26161", # Washtenaw
  "Grand Rapids", "MI", "26081", # Kent
  "Lansing", "MI", "26065", # Ingham
  
  # Ohio
  "Columbus", "OH", "39049", # Franklin
  "Columbus", "OH", "39041", # Delaware
  "Columbus", "OH", "39045", # Fairfield
  "Columbus", "OH", "39089", # Licking
  "Cleveland", "OH", "39035", # Cuyahoga
  "Cleveland", "OH", "39055", # Geauga
  "Cleveland", "OH", "39085", # Lake
  "Cleveland", "OH", "39103", # Medina
  "Cincinnati", "OH", "39061", # Hamilton
  "Cincinnati", "OH", "39025", # Clermont
  "Cincinnati", "OH", "39165", # Warren
  "Dayton", "OH", "39113", # Montgomery
  "Akron", "OH", "39153", # Summit
  "Cincinnati", "OH", "39017", # Butler
  
  # Pennsylvania
  "Philadelphia", "PA", "42101", # Philadelphia
  "Philadelphia", "PA", "42045", # Delaware
  "Philadelphia", "PA", "42091", # Montgomery
  "Philadelphia", "PA", "42017", # Bucks
  "Philadelphia", "PA", "42029", # Chester
  "Pittsburgh", "PA", "42003", # Allegheny
  "Pittsburgh", "PA", "42129", # Westmoreland
  "Pittsburgh", "PA", "42007", # Beaver
  "Lehigh Valley", "PA", "42077", # Lehigh
  "Lehigh Valley", "PA", "42095", # Northampton
  
  # Florida
  "Miami-Fort Lauderdale", "FL", "12086", # Miami-Dade
  "Miami-Fort Lauderdale", "FL", "12011", # Broward
  "Miami-Fort Lauderdale", "FL", "12099", # Palm Beach
  "Orlando", "FL", "12095", # Orange
  "Orlando", "FL", "12097", # Osceola
  "Orlando", "FL", "12117", # Seminole
  "Tampa", "FL", "12057", # Hillsborough
  "Tampa", "FL", "12103", # Pinellas
  "Tampa", "FL", "12081", # Manatee
  "Jacksonville", "FL", "12031", # Duval
  "Jacksonville", "FL", "12109", # St. Johns
  "Fort Myers-Naples", "FL", "12071", # Lee
  "Fort Myers-Naples", "FL", "12021", # Collier
  
  # Georgia
  "Atlanta", "GA", "13121", # Fulton
  "Atlanta", "GA", "13089", # DeKalb
  "Atlanta", "GA", "13067", # Cobb
  "Atlanta", "GA", "13135", # Gwinnett
  "Atlanta", "GA", "13063", # Clayton
  "Atlanta", "GA", "13057", # Cherokee
  "Atlanta", "GA", "13077", # Coweta
  "Atlanta", "GA", "13097", # Douglas
  "Atlanta", "GA", "13113", # Fayette
  "Atlanta", "GA", "13247", # Rockdale
  
  # Texas
  "Dallas-Fort Worth", "TX", "48113", # Dallas
  "Dallas-Fort Worth", "TX", "48439", # Tarrant
  "Dallas-Fort Worth", "TX", "48085", # Collin
  "Dallas-Fort Worth", "TX", "48121", # Denton
  "Houston", "TX", "48201", # Harris
  "Houston", "TX", "48157", # Fort Bend
  "Houston", "TX", "48339", # Montgomery
  "Austin", "TX", "48453", # Travis
  "Austin", "TX", "48491", # Williamson
  "San Antonio", "TX", "48029", # Bexar
  
  # North Carolina
  "Charlotte",       "NC", "37119", # Mecklenburg
  "Charlotte",       "NC", "37179", # Union
  
  "Raleigh-Durham",  "NC", "37183", # Wake
  "Raleigh-Durham",  "NC", "37063", # Durham
  "Raleigh-Durham",  "NC", "37135", # Orange
  "Raleigh-Durham",  "NC", "37101", # Johnston
  
  # Arizona
  "Phoenix", "AZ", "04013", # Maricopa
  "Phoenix", "AZ", "04021", # Pinal
  
  # California
  "Los Angeles", "CA", "06037", # Los Angeles
  "Orange County", "CA", "06059", # Orange
  "Inland Empire", "CA", "06065", # Riverside
  "Inland Empire", "CA", "06071", # San Bernardino
  "San Diego", "CA", "06073", # San Diego
  "Bay Area", "CA", "06075", # San Francisco
  "Bay Area", "CA", "06081", # San Mateo
  "Bay Area", "CA", "06085", # Santa Clara
  "Bay Area", "CA", "06001", # Alameda
  "Bay Area", "CA", "06013", # Contra Costa
  "Sacramento", "CA", "06067", # Sacramento
  
  # Washington
  "Seattle", "WA", "53033", # King
  "Seattle", "WA", "53061", # Snohomish
  "Seattle", "WA", "53053", # Pierce
  
  # Utah
  "Wasatch Front", "UT", "49035", # Salt Lake
  "Wasatch Front", "UT", "49049", # Utah
  "Wasatch Front", "UT", "49011", # Davis
  "Wasatch Front", "UT", "49057", # Weber
  
  # Colorado
  "Denver", "CO", "08031", # Denver
  "Denver", "CO", "08001", # Adams
  "Denver", "CO", "08005", # Arapahoe
  "Denver", "CO", "08059", # Jefferson
  "Boulder", "CO", "08013", # Boulder
  "Colorado Springs", "CO", "08041", # El Paso
  
  # Massachusetts
  "Boston", "MA", "25025", # Suffolk
  "Boston", "MA", "25017", # Middlesex
  "Boston", "MA", "25021", # Norfolk
  "Boston", "MA", "25009", # Essex
  
  # Maryland
  "Baltimore", "MD", "24005", # Baltimore County
  "Baltimore", "MD", "24510", # Baltimore City
  "Baltimore", "MD", "24003", # Anne Arundel
  "Baltimore", "MD", "24027", # Howard
  "Washington-Baltimore", "MD", "24031", # Montgomery
  "Washington-Baltimore", "MD", "24033",  # Prince George's
  
  # Wisconsin
  "Milwaukee", "WI", "55079", # Milwaukee
  "Milwaukee", "WI", "55133", # Waukesha
  "Milwaukee", "WI", "55089", # Ozaukee
  "Milwaukee", "WI", "55131", # Washington
  
  # Virginia
  "Northern Virginia", "VA", "51059", # Fairfax
  "Northern Virginia", "VA", "51107", # Loudoun
  "Northern Virginia", "VA", "51153", # Prince William
  "Northern Virginia", "VA", "51013", # Arlington
  "Northern Virginia", "VA", "51510", # Alexandria city
  "Northern Virginia", "VA", "51600",  # Fairfax city
  
  # Washington DC
  "Washington DC", "DC", "11001", # District of Columbia
  
  # Portland
  "Portland", "OR", "41051", # Multnomah
  "Portland", "OR", "41067", # Washington
  "Portland", "OR", "41005", # Clackamas
  
  # Las Vegas
  "Las Vegas", "NV", "32003", # Clark
  
  # New Jersey
  "Philadelphia", "NJ", "34007", # Camden
  "New York",     "NJ", "34017", # Hudson
  "New York",     "NJ", "34013", # Essex
  "New York",     "NJ", "34023"  # Middlesex
)

zcta_snap_amazon_markets <- zcta_snap_state %>%
  inner_join(
    amazon_fresh_counties,
    by = c("state", "county_fips")
  )

eligible_amazon_zips <- zcta_snap_state %>%
  inner_join(
    amazon_fresh_counties,
    by = c("state", "county_fips")
  ) %>%
  distinct(state, zipcode, .keep_all = TRUE)

high_pool <- eligible_amazon_zips %>%
  group_by(market, state) %>%
  filter(share_snap_hh >= quantile(share_snap_hh, 0.6, na.rm = TRUE)) %>%
  ungroup()

low_pool <- eligible_amazon_zips %>%
  group_by(market, state) %>%
  filter(share_snap_hh <= quantile(share_snap_hh, 0.2, na.rm = TRUE)) %>%
  ungroup()

market_summary <- bind_rows(
  high_pool %>% mutate(type = "High"),
  low_pool %>% mutate(type = "Low")
) %>%
  count(state, market, type)


high_top10 <- high_pool %>%
  arrange(state, market, desc(share_snap_hh)) %>%
  group_by(state, market, county_fips) %>%
  slice_head(n = 3) %>%
  ungroup() %>%
  group_by(state, market) %>%
  slice_head(n = 10) %>%
  mutate(group = "High SNAP") %>%
  ungroup()

low_top10 <- low_pool %>%
  arrange(state, market, share_snap_hh) %>%
  group_by(state, market, county_fips) %>%
  slice_head(n = 3) %>%
  ungroup() %>%
  group_by(state, market) %>%
  slice_head(n = 10) %>%
  mutate(group = "Low SNAP") %>%
  ungroup()

candidate_zips <- bind_rows(high_top10, low_top10)

candidate_zips %>%
  group_by(state, market) %>%
  summarize(
    n = n(),
    low_snap = min(share_snap_hh),
    high_snap = max(share_snap_hh),
    spread = high_snap - low_snap,
    .groups = "drop"
  ) %>%
  arrange(desc(spread))

candidate_zips <- candidate_zips %>%
  select(-res_ratio, -bus_ratio, -oth_ratio, -tot_ratio)

#write_csv(candidate_zips, "candidate_zips_fresh.csv")

