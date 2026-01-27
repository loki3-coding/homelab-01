-- Immich Database Initialization
-- Run this script as the PostgreSQL admin user to set up Immich database

-- Create Immich user (change password as needed)
CREATE USER immich WITH PASSWORD 'your_secure_password';

-- Create Immich database
CREATE DATABASE immich OWNER immich;

-- Connect to the immich database and create required extensions
\c immich

-- Required for ML/vector search features
CREATE EXTENSION IF NOT EXISTS vectors;

-- Required for location/map features
CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;

-- Grant all privileges to immich user
GRANT ALL PRIVILEGES ON DATABASE immich TO immich;
