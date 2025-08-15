-- Enable pgvector extension (optional, if you'll store embeddings)
CREATE EXTENSION IF NOT EXISTS vector;

-- Users & Roles
CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  collection_name TEXT,
  role_id INT REFERENCES roles(id)
);