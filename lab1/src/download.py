import kagglehub

# Download latest version
path = kagglehub.dataset_download("omercolakoglu/10million-rows-turkish-market-sales-dataset")

print("Path to dataset files:", path)