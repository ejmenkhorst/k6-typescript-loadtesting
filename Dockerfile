# Use the Alpine base image
FROM alpine:latest

# Set the working directory inside the container
WORKDIR /init-scripts

# Copy your shell script into the container
COPY /init-scripts/ /init-scripts/

# Ensure the script has execute permissions
RUN chmod +x /init-scripts/initial-setup.sh
RUN chmod +x /init-scripts/replicate.sh

# Install Bash if your script requires it
RUN apk add --no-cache bash curl

# Set the entrypoint to execute your script
ENTRYPOINT ["/init-scripts/initial-setup.sh"]