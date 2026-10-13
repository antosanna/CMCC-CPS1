#!/bin/bash

# Set the initial date 
initial_date="1993-01-01"

# Calculate the date 185 days later
result_date=$(date -d "$initial_date +184 days" +%Y-%m-%d)

echo "The day 185 days after $initial_date is $result_date"

