FROM golang:1.25-alpine AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /app
EXPOSE 5000

COPY go.mod go.sum ./
RUN go mod download

COPY . .
ENV CGO_ENABLED=0
RUN GOOS=linux GOARCH=amd64 go build -o whatsappapi

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netcat-openbsd \
    postgresql-client \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV TZ="America/Sao_Paulo"
WORKDIR /app

COPY --from=builder /app/whatsappapi         /app/
COPY --from=builder /app/static         /app/static/
COPY --from=builder /app/whatsappapi.service /app/whatsappapi.service

RUN chmod +x /app/whatsappapi && \
    chmod -R 755 /app && \
    chown -R root:root /app

ENTRYPOINT ["/app/whatsappapi", "--logtype=console", "--color=true"]
