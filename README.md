# IKA Protocol Monitoring Stack

This repository contains the configuration files and dashboards for monitoring the IKA Protocol (SUI Layer 2) using Prometheus and Grafana.

## Components

- `prometheus.yml`: Prometheus configuration file for scraping IKA metrics
- `ika_dashboard.json`: Grafana dashboard for visualizing IKA metrics

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

```bash
curl -fsSL https://get.docker.com | bash
```

## Setup

### 1. Set up environment variables (optional)

You can customize the Grafana admin credentials by setting environment variables:

```bash
# Create a .env file
echo "GRAFANA_ADMIN_USER=your_username" > .env
echo "GRAFANA_ADMIN_PASSWORD=your_secure_password" >> .env
```

If you don't set these variables, the default credentials (admin/admin) will be used.

### 2. Start the monitoring stack

```bash
docker-compose up -d
```

### 3. Configure Grafana

1. Open Grafana at http://localhost:3000
2. Log in with the credentials you specified in the .env file (or the default: username: admin, password: admin)
3. Navigate to Configuration > Data Sources
4. Add a new Prometheus data source:
   - Name: Prometheus
   - URL: http://prometheus:9090
   - Access: Server
5. Click "Save & Test" to verify the connection

### 4. Import the IKA Dashboard

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

## Customization

Feel free to modify the dashboard to suit your specific monitoring needs:

- Add more panels for specific metrics
- Create alerts for critical metrics
- Adjust time ranges for better visualization

## License

This project is licensed under the MIT License - see the LICENSE file for details. 