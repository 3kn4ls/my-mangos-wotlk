#!/bin/bash
# MaNGOS WotLK - Database Initialization Script
# This script creates the three required databases and sets up permissions

set -e

echo "Initializing MaNGOS databases..."

# Wait for MySQL to be ready
until mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  echo "Waiting for MySQL to be ready..."
  sleep 2
done

echo "MySQL is ready. Creating databases..."

# Create databases
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`realmd\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE DATABASE IF NOT EXISTS \`mangos\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE DATABASE IF NOT EXISTS \`characters\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    -- Create mangos user if it doesn't exist
    CREATE USER IF NOT EXISTS 'mangos'@'%' IDENTIFIED BY '${MYSQL_PASSWORD:-mangos}';

    -- Grant privileges
    GRANT ALL PRIVILEGES ON \`realmd\`.* TO 'mangos'@'%';
    GRANT ALL PRIVILEGES ON \`mangos\`.* TO 'mangos'@'%';
    GRANT ALL PRIVILEGES ON \`characters\`.* TO 'mangos'@'%';

    FLUSH PRIVILEGES;
EOSQL

echo "Databases created successfully!"
echo "- realmd: Authentication and realm data"
echo "- mangos: World data (creatures, items, quests, etc.)"
echo "- characters: Player character data"

# Import base schemas if they exist
if [ -d "/docker-entrypoint-initdb.d/base/mangos" ]; then
    echo "Importing base world database schema..."
    for sql_file in /docker-entrypoint-initdb.d/base/mangos/*.sql; do
        if [ -f "$sql_file" ]; then
            echo "Importing: $(basename $sql_file)"
            mysql -u root -p"${MYSQL_ROOT_PASSWORD}" mangos < "$sql_file"
        fi
    done
fi

if [ -d "/docker-entrypoint-initdb.d/base/realmd" ]; then
    echo "Importing base realmd database schema..."
    for sql_file in /docker-entrypoint-initdb.d/base/realmd/*.sql; do
        if [ -f "$sql_file" ]; then
            echo "Importing: $(basename $sql_file)"
            mysql -u root -p"${MYSQL_ROOT_PASSWORD}" realmd < "$sql_file"
        fi
    done
fi

if [ -d "/docker-entrypoint-initdb.d/base/characters" ]; then
    echo "Importing base characters database schema..."
    for sql_file in /docker-entrypoint-initdb.d/base/characters/*.sql; do
        if [ -f "$sql_file" ]; then
            echo "Importing: $(basename $sql_file)"
            mysql -u root -p"${MYSQL_ROOT_PASSWORD}" characters < "$sql_file"
        fi
    done
fi

echo "Database initialization complete!"
