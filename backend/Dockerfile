FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download 2>/dev/null || true
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./cmd/api/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata curl
WORKDIR /root/
COPY --from=builder /app/server .
# ✅ HuggingFace PORT=7860
EXPOSE 7860
ENV PORT=7860
CMD ["./server"]
