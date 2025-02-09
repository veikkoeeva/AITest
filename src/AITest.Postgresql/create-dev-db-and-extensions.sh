#!/bin/bash
# database name
db_name="devaitest"

# Create the database (if it doesn't exist).
psql --command="create database $db_name;"

# Change the owner of the database to postgres.
psql --command="alter database $db_name owner to postgres;"

# Connect to the database and create the extensions.
psql --dbname=$db_name <<EOF
create extension if not exists postgis schema public;
create extension if not exists vector schema public;
create extension if not exists pg_duckdb schema public;
EOF
