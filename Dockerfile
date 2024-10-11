# Use the official Ghost image as the base
FROM ghost:latest

# Set environment variables
ENV NODE_ENV=development

# Expose the port that Ghost runs on
EXPOSE 2368
