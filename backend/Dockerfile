FROM golang:1.22-alpine AS builder
WORKDIR /app

# Насб кардани git (барои бор кардани баъзе китобхонаҳо лозим аст)
RUN apk add --no-cache git

# Нусхабардории файлҳои танзимоти Go
COPY go.mod go.sum* ./

# Тоза ва автоматӣ насб кардани тамоми китобхонаҳои намерасидагӣ
RUN go mod tidy
RUN go mod download

# Нусхабардории тамоми коди барнома
COPY . .

# Боз як бор тафтиш ва компилятсияи код
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -o tajikshop-api ./cmd/api/main.go

FROM alpine:3.19
WORKDIR /app

# Нусхабардории файли бинарии тайёр
COPY --from=builder /app/tajikshop-api .

RUN chmod +x tajikshop-api
EXPOSE 7860
ENV PORT=7860
ENV GIN_MODE=release

CMD ["./tajikshop-api"]
