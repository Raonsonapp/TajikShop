package storage

import (
	"bytes"
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type R2 struct {
	Client     *s3.Client
	Bucket     string
	AccountID  string
}

// сохтани client
func NewR2(accountID, accessKey, secretKey, bucket string) *R2 {
	endpoint := "https://" + accountID + ".r2.cloudflarestorage.com"

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion("auto"),
		config.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(accessKey, secretKey, ""),
		),
	)

	if err != nil {
		log.Fatal("R2 config error:", err)
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
	})

	return &R2{
		Client:    client,
		Bucket:    bucket,
		AccountID: accountID,
	}
}

// upload файл
func (r *R2) Upload(fileName string, file []byte) (string, error) {
	_, err := r.Client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: &r.Bucket,
		Key:    &fileName,
		Body:   bytes.NewReader(file),
	})

	if err != nil {
		return "", err
	}

	// ✔ ДУРУСТ URL (бе EndpointResolverV2)
	url := "https://" + r.Bucket + "." + r.AccountID + ".r2.cloudflarestorage.com/" + fileName

	return url, nil
}
