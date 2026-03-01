# Simple Flutter development/build container.
# Use the maintained CirrusLabs registry to get a modern Flutter/Dart toolchain.
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy project
COPY . .

# Default to an interactive shell so the container can be used for builds
CMD ["bash"]
