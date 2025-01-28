
# src/weight-service/Dockerfile

FROM python:3.10-slim

# Copy your code and install dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app

# Expose any ports if needed (for HTTP publisher, for instance)
# EXPOSE 8000

CMD ["python", "app.py"]