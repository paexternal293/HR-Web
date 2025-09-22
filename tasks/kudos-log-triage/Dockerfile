FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        python3-pip \
        tmux \
        asciinema \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN mkdir -p /workspace/logs
COPY resources/kudos-access.log /workspace/logs/kudos-access.log
RUN chmod 644 /workspace/logs/kudos-access.log
