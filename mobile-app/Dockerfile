# Simple Flutter development/build container
FROM cirrusci/flutter:stable

WORKDIR /app

# Cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy project
COPY . .

# Default to an interactive shell so the container can be used for builds
CMD ["bash"]
