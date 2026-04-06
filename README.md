ShopPrime 2.0 – Database Project

Overview
This project is for COMP 640 - Graduate Database Systems. We are building a relational backend using Neon PostgreSQL and Python.

Project Setup

Clone the repository

Install dependencies
pip install -r requirements.txt

Environment Variables (.env)

Create a .env file in the root folder.

Add this line:
DATABASE_URL=your_neon_connection_string_here

IMPORTANT: Do NOT commit the .env file.

Getting the Neon Connection String

Go to https://neon.tech
Open your project
Click “Connection Details”
Copy the connection string

It will look like:
postgresql://username:password@host/dbname?sslmode=require

Paste it into your .env file.

Testing Database Connection

Run:
python src/db.py

You should see a success message if connected.

Database Setup (Migrations)

All SQL files are in the migrations/ folder.

To create tables (V1):

Open migrations/V1__create_tables.sql
Copy everything
Paste into Neon SQL Editor
Click Run

Project Structure

shop_prime/

src/ (Python code)
migrations/ (SQL files)
requirements.txt
.env (not committed)
.gitignore
README.md

Important Notes

Use migration files for database changes (do not edit tables manually in Neon unless testing)

Team Workflow

Database changes → migrations folder
Python code → src folder
Use clear commit messages

Example:
Add customers and addresses tables (V1)

Current Progress

Neon database setup
Python connection working
Initial schema (V1)
Constraints (V2)
RBAC (V3)

Next Steps

Add indexes
Add Materialized view
Build stored procedures
Create seed and concurrency scripts
