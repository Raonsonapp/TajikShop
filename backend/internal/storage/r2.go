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
	Client *s3.Client
	Bucket string
}

// сохтани client барои Cloudflare R2
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
		Client: client,
		Bucket: bucket,
	}
}

// upload файл ба R2
func (r *R2) Upload(fileName string, file []byte) (string, error) {
	_, err := r.Client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: &r.Bucket,
		Key:    &fileName,
		Body:   bytes.NewReader(file),
	})

	if err != nil {
		return "", err
	}

	// линк барои дастрасӣ
	url := "https://" + r.Bucket + "." + r.Client.EndpointResolverV2.ResolveEndpoint(
		context.TODO(),
		s3.EndpointParameters{},
	).URI.Host + "/" + fileName

	return url, nil
}
