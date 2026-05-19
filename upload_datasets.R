source("load.R")

# Upload all resource files, replacing existing versions
# This assumes that matching datasets *already exist* on the destination CKAN instance.


# Order the catalog for alphabetical resource names (per dataset)

catalog <- catalog |> 
  arrange(
    destination_dataset,
    title
  )


# This iterates through the catalog dataset, rather than file folders, to also include resource titles and descriptions.

upsert_all_package_resources(catalog)


# Run log:

run_log |> 
  write_csv("log/run_log.csv")
