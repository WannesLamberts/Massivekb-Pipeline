# Use the official Python 3.12 image as the base image
FROM python:3.12-slim

# Update the package list and install required packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the requirements file to the image
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt
