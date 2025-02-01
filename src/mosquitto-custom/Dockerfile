FROM eclipse-mosquitto:2.0.18

# Copy the custom configuration file into the image
COPY mosquitto.conf /mosquitto/config/mosquitto.conf

# (Optional) Create the log directory
RUN mkdir -p /mosquitto/log
