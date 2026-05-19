source("lib/helpers.R")




catalog_path <- "https://hub.arcgis.com/api/feed/all/csv?target=community-statistics.service.yukon.ca"

catalog <- read_csv(catalog_path)

# Categorize entries to open.yukon.ca datasets

catalog <- catalog |> 
  mutate(
    destination_dataset = case_when(
      str_detect(title, "Census 2011") ~ "census-2011-census-profile",
      str_detect(title, "Census 2016") ~ "census-2016-census-profile",
      str_detect(title, "Census 2021") ~ "census-2021-census-profile",
      
      # Fix for Labour Force by Industry (2021)
      # which is missing "Census 2021" in the title part
      str_detect(title, "(2021)") ~ "census-2021-census-profile",
      
      str_detect(categories, "Economic") ~ "economic-statistics",
      str_detect(categories, "Demographic") ~ "demographic-statistics",
      str_detect(categories, "Social") ~ "social-statistics",
      str_detect(categories, "Employment") ~ "employment-statistics",
      str_detect(categories, "Housing") ~ "housing-statistics",
      
      .default = title
    )
  )

# Generate the CSV download URL

catalog <- catalog |> 
  mutate(
    csv_download_url = generate_csv_download_url_from_arcgis_id(id),
    csv_file_name = str_c(slugify(title), ".csv")
  )


# Save the catalog as a backup / change tracker for the future
catalog |> 
  write_csv("input/catalog.csv")


for (i in seq_along(catalog$id)) { 
  
  add_log_entry("Retrieving ", catalog$title[i])
  
  download_and_save_arcgis_csv_file(
    catalog$csv_download_url[i],
    catalog$destination_dataset[i],
    catalog$csv_file_name[i]
    
  )
  
  Sys.sleep(1)
  
}


# Export the run log:

run_log |> 
  write_csv("log/run_log.csv")

