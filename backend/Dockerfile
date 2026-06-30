FROM golang:1.25-alpine AS builder
WORKDIR /app

RUN apk --no-cache add git

COPY . .

# ✅ go.sum-ро худаш месозад
RUN go mod tidy && go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -o server ./cmd/api/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/server .
EXPOSE 7860
ENV PORT=7860
CMD ["./server"]
