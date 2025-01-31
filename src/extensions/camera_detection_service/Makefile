# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

.PHONY: install setup run stop clean logs

SERVICE_DIR := .
VENV := $(SERVICE_DIR)/venv
PYTHON := $(VENV)/bin/python
REQUIREMENTS := $(SERVICE_DIR)/requirements.txt
BACKEND := $(SERVICE_DIR)/backend/main.py
FRONTEND := $(SERVICE_DIR)/frontend/front.py
BACKEND_PORT := 8080

install:
	@echo "Setting up virtual environment and installing dependencies..."
	@if [ ! -d "$(VENV)" ]; then \
		python3 -m venv $(VENV); \
	fi
	@$(PYTHON) -m pip install --upgrade pip
	@if [ -f "$(REQUIREMENTS)" ]; then \
		$(PYTHON) -m pip install -r $(REQUIREMENTS); \
	else \
		echo "Warning: No requirements.txt found!"; \
	fi

setup: install
	@echo "Environment setup completed."

run:
	@echo "Starting backend service on port $(BACKEND_PORT)..."
	@$(PYTHON) $(BACKEND) --port $(BACKEND_PORT) &
	@sleep 2
	@echo "Starting frontend service..."
	@$(PYTHON) $(FRONTEND) &
	@echo "Services running. Press Ctrl+C to stop."

stop:
	@echo "Stopping services..."
	@pkill -f $(BACKEND) || true
	@pkill -f $(FRONTEND) || true
	@echo "Services stopped."

clean:
	@echo "Cleaning virtual environment and temporary files..."
	@rm -rf $(VENV) __pycache__ *.pyc *.pyo *.log

logs:
	@echo "Displaying logs..."
	@tail -f logs/service.log
