#!/bin/bash

# Application deployment script for Azure VMs
set -e

# Configuration
APP_NAME="${app_name}"
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
ROLE="${role}"

echo "Starting deployment for $APP_NAME ($ROLE tier) in $ENVIRONMENT environment"

# Update system
apt-get update
apt-get upgrade -y

# Install common dependencies
apt-get install -y python3 python3-pip python3-venv nginx mysql-client

# Create application directory
mkdir -p /opt/$APP_NAME
cd /opt/$APP_NAME

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install flask gunicorn mysql-connector-python

# Create application file
cat > app.py << EOF
from flask import Flask, jsonify
import mysql.connector
import socket
import os

app = Flask(__name__)

# Database configuration (will be set by environment variables)
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'appdb'),
    'user': os.getenv('DB_USER', 'dbadmin'),
    'password': os.getenv('DB_PASS', ''),
    'port': os.getenv('DB_PORT', '3306')
}

@app.route('/')
def index():
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        db_status = "connected"
        cursor.close()
        conn.close()
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    return jsonify({
        'application': '$APP_NAME',
        'version': '1.0.0',
        'environment': '$ENVIRONMENT',
        'role': '$ROLE',
        'hostname': hostname,
        'ip_address': ip_address,
        'database': db_status,
        'status': 'healthy'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$APP_PORT)
EOF

# Create systemd service
cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=$APP_NAME Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/$APP_NAME
Environment="PATH=/opt/$APP_NAME/venv/bin"
Environment="DB_HOST=app-mysql-server.mysql.database.azure.com"
Environment="DB_NAME=appdb"
Environment="DB_USER=dbadmin"
Environment="DB_PASS=SecurePassword123!"
Environment="DB_PORT=3306"
ExecStart=/opt/$APP_NAME/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:$APP_PORT app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx (for public VMs only)
if [ "$ROLE" = "web" ]; then
    cat > /etc/nginx/sites-available/$APP_NAME << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    systemctl restart nginx
fi

# Enable and start application service
systemctl daemon-reload
systemctl enable $APP_NAME
systemctl start $APP_NAME

echo "Deployment completed successfully!"
echo "Application is running on port $APP_PORT"