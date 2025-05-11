# R4R or Ready 4 Review or r10w
FROM python:3.12-alpine3.21 AS base

# Install system dependencies
RUN apk update && \
    apk add --no-cache \
        git \
        openssh-client \
        wget \
        curl \
        github-cli \
        ripgrep \
        tar && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install ra-aid aider

FROM base AS final
# Set working directory
WORKDIR /app
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["sh", "./entrypoint.sh"]
