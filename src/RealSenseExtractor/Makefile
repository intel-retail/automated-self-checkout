# Create and run the Docker container(s)
up:
	docker-compose up

# Shut down the Docker container(s)
down:
	docker-compose down

# Run unit tests
test:
	python -m unittest ./UnitTests/KafkaPublisherTest.py
	python -m unittest ./UnitTests/GraphanaPublisherTest.py
	python -m unittest ./UnitTests/MicroServicePublisherTest.py

# Build the Docker container(s)
build:
	docker-compose build

# Run the Docker container(s)
run:
	docker-compose start