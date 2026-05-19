library(tidyverse)
library(jsonlite)
library(janitor)
library(fs)

# Logging helper ----------------------------------------------------------

run_log <- tribble(
  ~time, ~message
)

# Logging helper function
add_log_entry <- function(...) {
  
  log_text <- str_c(...)
  
  new_row = tibble_row(
    time = now(),
    message = log_text
  )
  
  run_log <<- run_log |>
    bind_rows(
      new_row
    )
  
  cat(log_text, "\n")
}

run_start_time <- now()
add_log_entry(str_c("Start time was: ", run_start_time))


# CKAN setup --------------------------------------------------------------

# if(file_exists(".env")) {
#   readRenviron(".env")
#   
#   ckan_url <- Sys.getenv("ckan_url")
#   
#   ckanr_setup(
#     url = ckan_url, 
#     key = Sys.getenv("ckan_api_token")
#   )
#   
# } else {
#   stop("No .env file found, create it before running this script.")
# }



# ArcGIS retrieval functions ----------------------------------------------

generate_csv_download_url_from_arcgis_id <- function(arcgis_id) {
  
  str_c(
    "https://hub.arcgis.com/api/v3/datasets/",
    arcgis_id,
    "_0/downloads/data?format=csv&spatialRefId=4326&where=1%3D1"
  )
  
}

# Thanks, Google
slugify <- function(x) {
  x %>%
    str_to_lower() %>%                        # Convert to lowercase
    iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT') %>% # Convert accented characters to ASCII before removing non-ASCII below
    str_replace_all("[^a-z0-9\\s-]", "") %>%  # Remove non-alphanumeric (except spaces/hyphens)
    str_squish() %>%                          # Remove extra whitespace
    str_replace_all("\\s+", "-") %>%          # Replace spaces with hyphens
    str_replace_all("-{2,}", "-")             # Replace multiple hyphens with singular ones
}


post_process_cs_data <- function(df) {
  
  df <- df |> 
    clean_names()
  
  df <- df |> 
    relocate(
      any_of("census_year"),
      any_of("year"),
      any_of("quarter"),
      any_of("month"),
      any_of("region"),
      any_of("geo_name"),
      
      any_of("category"),
      any_of("subcategory"),
      any_of("sub_category"),
      any_of("variable_name"),
      any_of("topic"),
      
      any_of("total"),
      any_of("male"),
      any_of("female"),
      any_of("flag_total"),
      any_of("flag_male"),
      any_of("flag_female"),
      # any_of("regionzz"),
      # everything(),
      !any_of("geographic_boundary"),
      any_of("geographic_boundary")
    )
  
  # Clear empty rows (resolves an issue with the Crime dataset)
  df <- df |> 
    drop_na(any_of("year"))
  
  # Unselect object_id
  df <- df |> 
    select(
      !any_of("object_id")
    )
  
  df
  
}


download_and_save_arcgis_csv_file <- function(csv_download_url, destination_dataset, csv_file_name) {
  
  add_log_entry("Downloading ", csv_download_url, " to ", destination_dataset, "/", csv_file_name)
  
  csv_data <- NULL;
  
  tryCatch({
    csv_data <- read_csv(csv_download_url)
  }, error = function(e) {
    add_log_entry(e$message)
    add_log_entry("Error: could not download ", csv_download_url)
  })
  
  if(is.null(csv_data)) {
    # Stop this function:
    return(NULL)
  }
  
  csv_data <- post_process_cs_data(csv_data)
  
  dir_create(str_c("output/", destination_dataset))
  
  write_csv(csv_data, str_c("output/", destination_dataset, "/", csv_file_name), na = "")
  
}
