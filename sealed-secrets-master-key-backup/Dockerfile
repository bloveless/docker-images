FROM golang:1.18-alpine as builder

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . .

RUN go build -o /app/build/sealed-secrets-master-key-backup

FROM alpine:3.15

COPY --from=builder --chmod=544 /app/build/sealed-secrets-master-key-backup /sealed-secrets-master-key-backup

ENTRYPOINT ["/sealed-secrets-master-key-backup"]

