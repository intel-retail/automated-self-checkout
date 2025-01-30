build:
	# $(MAKE) install-infinity
	docker compose -f docker-compose.datavis.yml build --no-cache

install-infinity:
	docker exec -it grafana grafana cli plugins install yesoreyeram-infinity-datasource

run:
	docker compose -f docker-compose.datavis.yml up -d

down:
	docker compose -f docker-compose.datavis.yml down