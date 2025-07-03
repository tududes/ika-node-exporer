# IKA Protocol Monitoring Stack

This repository contains the configuration files and dashboards for monitoring the IKA Protocol (SUI Layer 2) using Prometheus and Grafana.

## Components

- `prometheus.yml`: Prometheus configuration file with environment variable placeholders for scraping metrics
- `ika_dashboard.json`: Grafana dashboard for visualizing IKA metrics

## Environment Variable Substitution

The `prometheus.yml` file uses environment variable placeholders (`${IKA_METRICS_TARGET}` and `${SUI_METRICS_TARGET}`) that are substituted by the setup script to generate the actual configuration. The original file is backed up as `prometheus.yml.original` before substitution.

Additionally, the `VN_AUTHORITY` variable is used to customize the Grafana dashboard with your validator's authority name. The setup script will replace the default "VN_AUTHORITY" placeholder in the dashboard with your actual validator name.

### Example .env file format:
```
DOMAIN=ika.example.com
GRAFANA_ADMIN_PASSWORD=your_secure_password
SUI_METRICS_TARGET=172.17.0.1:9284
IKA_METRICS_TARGET=172.17.0.1:9184
VN_AUTHORITY=MyValidator
```

## Clone the repository

```bash
git clone https://github.com/tududes/ika-node-exporter.git
cd ika-node-exporter
```

## Quick installation (automated)

The repository ships with a helper script `setup.sh` that installs all dependencies, secures Grafana behind HTTPS, and launches the monitoring stack for you.

### What the script does
1. Installs Docker, Docker Compose, Nginx and Certbot.
2. Prompts for a public domain name (e.g. `grafana.example.com`) and a Grafana admin password (stored in `.env`).
3. Configures an Nginx reverse-proxy with a Let's Encrypt TLS certificate on ports 80/443.
4. Starts Prometheus and Grafana with `docker compose up -d`.
5. Prints the contents of `ika_dashboard.json` so you can import the dashboard with a single copy-paste.

Run it (as **root** or with `sudo`) using **one of the options below**:

**Option 1 – run the local script (after cloning):**
```bash
sudo bash setup.sh       # or: chmod +x setup.sh && sudo ./setup.sh
```

**Option 2 – execute in one line (without cloning first):**
```bash
bash <(curl -sL https://raw.githubusercontent.com/tududes/ika-node-exporter/main/setup.sh)
```

After the script finishes you can reach:
- **Grafana** at `https://<YOUR_DOMAIN>` (login: `admin` / the password you entered).
- **Prometheus** from inside Grafana at `http://prometheus:9090`.

If you do not have a domain name you can still access Grafana at `http://<SERVER_IP>:3000`, but HTTPS will not be configured.

---

## Manual Setup (Docker Compose)

### 1. Set up environment variables (optional)

You can customize the Grafana admin credentials by setting environment variables:

```bash
# Create a .env file
echo "GRAFANA_ADMIN_USER=your_username" > .env
echo "GRAFANA_ADMIN_PASSWORD=your_secure_password" >> .env
echo "SUI_METRICS_TARGET=172.17.0.1:9284" >> .env
echo "IKA_METRICS_TARGET=172.17.0.1:9184" >> .env
echo "VN_AUTHORITY=MyValidator" >> .env
```

If you don't set these variables, the default credentials (admin/admin) will be used for Grafana. However, the metrics targets are required for Prometheus to scrape the nodes.

### 2. Generate prometheus.yml from original

If you're setting up manually or have updated your `.env` file, generate the `prometheus.yml` file:

```bash
source .env
# Backup original if not already done
[ ! -f prometheus.yml.original ] && cp prometheus.yml prometheus.yml.original
# Generate prometheus.yml with substituted values
sed "s|\${IKA_METRICS_TARGET}|$IKA_METRICS_TARGET|g; s|\${SUI_METRICS_TARGET}|$SUI_METRICS_TARGET|g" prometheus.yml.original > prometheus.yml
```

### 3. Update Grafana dashboard (if needed)

If you need to update the validator authority name in the Grafana dashboard:

```bash
# Backup the original dashboard
cp Grafana-TrustedPoint-Ika-Sui.json Grafana-TrustedPoint-Ika-Sui.json.original

# Replace VN_AUTHORITY with your validator name
sed -i "s/VN_AUTHORITY/$VN_AUTHORITY/g" Grafana-TrustedPoint-Ika-Sui.json
```

### 4. Start the monitoring stack

```bash
docker-compose up -d
```

### 5. Configure Grafana

1. Open Grafana at http://localhost:3000
2. Log in with the credentials you specified in the .env file (or the default: username: admin, password: admin)
3. Navigate to Configuration > Data Sources
4. Add a new Prometheus data source:
   - Name: Prometheus
   - URL: http://prometheus:9090
   - Access: Server
5. Click "Save & Test" to verify the connection

### 6. Import the IKA Dashboard

1. In Grafana, navigate to Dashboards > Import
2. Click "Upload JSON file" and select the `ika_dashboard.json` file
3. Set the Prometheus data source to the one you created
4. Click "Import"

## Dashboard Overview

The IKA Protocol dashboard provides insights into:

1. **Consensus Overview**
   - Highest accepted round
   - Last committed leader round
   - Accepted blocks rates

2. **Network**
   - Inbound and outbound inflight requests
   - Request latencies

3. **Block Management**
   - Missing blocks and ancestors
   - Block commit latency
   - Authority reputation scores
   - Block proposal rates

4. **Database**
   - RocksDB metrics
   - Memory usage

## Troubleshooting

- Ensure that your IKA node is running and exposing metrics on port 9184
- Check Prometheus targets at http://localhost:9090/targets to ensure IKA metrics are being scraped
- If metrics are not being scraped, check that the IKA node is accessible from the Prometheus container
- If you see `${IKA_METRICS_TARGET}` or `${SUI_METRICS_TARGET}` in the Prometheus targets page instead of actual values:
  - Ensure the `.env` file exists and contains the correct variables
  - Restart the containers with `docker-compose down` followed by `docker-compose up -d`
  - Check container logs with `docker-compose logs prometheus` to see if there are any errors during startup

## Customization

Feel free to modify the dashboard to suit your specific monitoring needs:

- Add more panels for specific metrics
- Create alerts for critical metrics
- Adjust time ranges for better visualization

## License

This project is licensed under the MIT License - see the LICENSE file for details.