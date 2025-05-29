# Setting Up Pre-configured PostgreSQL Database with pgAdmin4 in Docker

This project provides a `docker-compose` setup to easily spin up a PostgreSQL database along with an instance of pgAdmin4, which can be accessed from your web browser. The setup also supports auto-loading of predefined SQL dump files into the PostgreSQL database.

## How to Run

### 1. Define Custom Dump Files

The `sql` directory contains dump files, which are SQL files that define various databases. Each file represents a different PostgreSQL database schema. The `run_docker.sh` script will:

- Create the corresponding database in PostgreSQL.
- Run the SQL commands from each dump file against its respective database.


### 2. Create the `.env` File 

To configure your environment, rename the `.env-example` file to `.env` and update the credentials (username, password) to your preferred values. This file will be used by the Docker containers and other scripts to configure access to the PostgreSQL database and pgAdmin4.

### 3. Spin Up the Docker Compose Setup + Run/Seed Databases via `run_docker.sh`

Follow these steps to launch the Docker containers and load your databases:

1. Navigate to the directory containing the `run_docker.sh` file.

    ```bash
    cd /path/to/your/repo
    ```

2. Ensure that the `run_docker.sh` file is executable. If it's not, make it executable with the following command:

    ```bash
    chmod +x run_docker.sh
    ```

3. Run the `run_docker.sh` script to start the Docker containers and load the dump files:

    ```bash
    ./run_docker.sh
    ```

The `run_docker.sh` script will do the following:

- Load the `.env` file to retrieve necessary environment variables.
- Create PostgreSQL databases based on the SQL dump files in the `sql` directory.
- Populate the created databases with the content from the corresponding `.sql` files (each database name matches the respective SQL file name).