# Install necessary packages
install.packages(c("tidyverse", "lubridate", "readxl"))
library(tidyverse)
library(lubridate)
library(readxl)

install.packages("conflicted")
library(conflicted)

# Define the folder path containing CSV files
folder_path <- "/Users/viviana/Documents/CYCLISTIC/year"
csv_files <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE)

# Read all CSV files and store them in a list
trip_data_list <- lapply(csv_files, read_csv)

# Combine all datasets into one
all_trip_data <- bind_rows(trip_data_list)

# Check the dimensions and first rows of the combined data
dim(all_trip_data)
head(all_trip_data)

# Check the structure of the combined dataset
glimpse(all_trip_data)

# Summary statistics for numerical columns
summary(all_trip_data)

# Create new columns for ride length and day of the week
all_trip_data <- all_trip_data %>%
  mutate(
    ride_length = as.numeric(difftime(ended_at, started_at, units = "mins")),
    day_of_week = wday(started_at, label = TRUE)
  ) %>%
  dplyr::filter(ride_length > 0)  # Remove invalid data

# Remove rows with missing or inconsistent data
all_trip_data <- drop_na(all_trip_data)

# Identify duplicate rows
duplicated_rows <- all_trip_data %>%
  dplyr::filter(duplicated(.))

# Print duplicate rows
print(duplicated_rows)

# Count the number of duplicate rows
num_duplicated <- all_trip_data %>%
  dplyr::filter(duplicated(.)) %>%
  nrow()

print(paste("Number of duplicate rows:", num_duplicated))

# Count missing values per column
sum(is.na(all_trip_data))
colSums(is.na(all_trip_data))

# Filter rows with at least one missing value
rows_with_na <- all_trip_data %>% 
  dplyr::filter(if_any(everything(), is.na))

# Display rows with missing values
print(rows_with_na)

# Count the number of rows with missing values
num_rows_with_na <- nrow(rows_with_na)
cat("Number of rows with missing values:", num_rows_with_na, "\n")

# Fill missing values in specific columns
all_trip_data <- all_trip_data %>%
  mutate(
    start_station_name = replace_na(start_station_name, "Unknown Start Station"),
    start_station_id = replace_na(start_station_id, "Unknown Start ID"),
    end_station_name = replace_na(end_station_name, "Unknown End Station"),
    end_station_id = replace_na(end_station_id, "Unknown End ID"),
    end_lat = replace_na(end_lat, median(end_lat, na.rm = TRUE)),
    end_lng = replace_na(end_lng, median(end_lng, na.rm = TRUE))
  )

# Recalculate ride length
all_trip_data <- all_trip_data %>%
  mutate(
    ride_length = as.numeric(difftime(ended_at, started_at, units = "mins"))
  )

# Validate ride length calculations
summary(all_trip_data$ride_length)

# Identify rides with duration <= 0
sum(all_trip_data$ride_length <= 0)

# Remove rows where ride length is 0
all_trip_data <- all_trip_data %>%
  dplyr::filter(ride_length > 0)

# Ensure there are no more invalid ride lengths
sum(all_trip_data$ride_length <= 0)  

# Calculate key metrics: average ride length, total rides by user type
summary_stats <- all_trip_data %>%
  group_by(member_casual) %>%
  summarize(
    avg_ride_length = mean(ride_length, na.rm = TRUE),
    total_rides = n()
  )

# Extract and format the day of the week
all_trip_data <- all_trip_data %>%
  mutate(day_of_week = wday(started_at, label = TRUE, abbr = FALSE))

# Group and analyze trends by user type and day of the week
trends <- all_trip_data %>%
  group_by(member_casual, day_of_week) %>%
  summarize(
    avg_ride_length = mean(ride_length, na.rm = TRUE),
    total_rides = n(),
    .groups = 'drop'
  )

# Sort days of the week in proper order
trends <- trends %>%
  mutate(day_of_week = factor(day_of_week, levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")))

# Calculate the longest ride duration
max_ride_length <- max(all_trip_data$ride_length, na.rm = TRUE)
print(max_ride_length)

# Identify the most frequent day of the week for rides
mode_day_of_week <- names(which.max(table(all_trip_data$day_of_week)))
print(mode_day_of_week)

# Load additional libraries
library(scales)

# Number of rides per month by user type
rides_per_month <- all_trip_data %>%
  mutate(month = month(started_at, label = TRUE, abbr = FALSE)) %>%
  group_by(member_casual, month) %>%
  summarise(count_rides = n(), .groups = "drop") %>%
  mutate(month = factor(month, levels = month.name))

# Plot number of rides per month
ggplot(rides_per_month, aes(x = month, y = count_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("casual" = "#1f78b4", "member" = "#33a02c")) +
  labs(title = "Number of Rides per Month by User Type",
       x = "Month",
       y = "Number of Rides",
       fill = "User Type") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12))

# Number of rides per weekday by user type
rides_per_day <- all_trip_data %>%
  group_by(member_casual, day_of_week) %>%
  summarise(count_rides = n(), .groups = "drop")

# Plot number of rides per weekday
ggplot(rides_per_day, aes(x = day_of_week, y = count_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("casual" = "#1f78b4", "member" = "#33a02c")) +
  labs(title = "Number of Rides per Day of the Week by User Type",
       x = "Day of the Week",
       y = "Number of Rides",
       fill = "User Type") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12))

# Calculate average ride duration by user type
ride_duration <- all_trip_data %>%
  group_by(member_casual) %>%
  summarise(avg_ride_length = mean(ride_length, na.rm = TRUE), .groups = "drop")

# Plot average ride duration
ggplot(ride_duration, aes(x = member_casual, y = avg_ride_length, fill = member_casual)) +
  geom_col() +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("casual" = "#1f78b4", "member" = "#33a02c")) +
  labs(title = "Average Ride Duration by User Type",
       x = "User Type",
       y = "Average Duration (minutes)",
       fill = "User Type") +
  theme_minimal()

# Peak usage hours analysis
rides_per_hour <- all_trip_data %>%
  mutate(hour = hour(started_at)) %>%
  group_by(member_casual, hour) %>%
  summarise(count_rides = n(), .groups = "drop")

# Plot rides per hour
ggplot(rides_per_hour, aes(x = hour, y = count_rides, color = member_casual, group = member_casual)) +
  geom_line(linewidth = 1.2) +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  scale_y_continuous(labels = scales::comma) +
  scale_color_manual(values = c("casual" = "#1f78b4", "member" = "#33a02c")) +
  labs(title = "Number of Rides per Hour of the Day by User Type",
       x = "Hour of the Day",
       y = "Number of Rides",
       color = "User Type") +
  theme_minimal()

# Analysis of the most used stations
# Count rides per start station and user type
top_stations <- all_trip_data %>%
  group_by(member_casual, start_station_name) %>%
  summarise(count_rides = n(), .groups = "drop") %>%
  arrange(member_casual, desc(count_rides)) %>%
  group_by(member_casual) %>%
  slice_head(n = 10)  # Select the top 10 most used stations per user type

# Plot Top 10 Most Used Stations by User Type
ggplot(top_stations, aes(x = reorder(start_station_name, count_rides), y = count_rides, fill = member_casual)) +
  geom_col() +
  coord_flip() +  # Flip the chart for better visualization
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("casual" = "#1f78b4", "member" = "#33a02c")) +
  labs(title = "Top 10 Most Used Stations by User Type",
       x = "Station Name",
       y = "Number of Rides",
       fill = "User Type") +
  theme_minimal()

