FROM grafana/grafana:latest

# Copy provisioning configuration
COPY provisioning/dashboards/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml

# Copy your dashboard JSON files to a folder where Grafana can pick them up
# (This folder must match the 'path' you specified in dashboards.yaml)
COPY dashboards/ /etc/grafana/provisioning/dashboards/

# (Optional) Expose the default port (3000)
EXPOSE 3000
