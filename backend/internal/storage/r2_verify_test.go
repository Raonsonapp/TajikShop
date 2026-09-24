package storage

import (
	"errors"
	"strings"
	"testing"
)

// classifyR2Error — хатои Cloudflare-ро ба паёми фаҳмо табдил медиҳад.
//
// Ин маҳз ҳамон ҷоест, ки ҳангоми ИВАЗ КАРДАНИ калидҳои R2 кор мекунад:
// агар калиди нав нодуруст бошад, бояд «credentials rejected» гӯяд, на
// «unreachable» — вагарна одам шабакаро мекобад, дар ҳоле ки айб дар калид аст.
func TestClassifyR2Error(t *testing.T) {
	cases := []struct {
		name string
		err  error
		want string
	}{
		{"ҳама дуруст", nil, "ok"},
		{"калиди нодуруст", errors.New(
			"operation error S3: HeadBucket, https response error StatusCode: 403, " +
				"api error InvalidAccessKeyId: The Access Key Id you provided does not exist"),
			"credentials rejected"},
		{"имзо нодуруст (секрет хато)", errors.New(
			"api error SignatureDoesNotMatch: The request signature we calculated does not match"),
			"credentials rejected"},
		{"дастрасӣ манъ", errors.New("api error AccessDenied: Access Denied"),
			"credentials rejected"},
		{"403-и хом", errors.New("https response error StatusCode: 403"),
			"credentials rejected"},
		{"bucket нест", errors.New("api error NoSuchBucket: The specified bucket does not exist"),
			"bucket not found"},
		{"шабака", errors.New("dial tcp: lookup r2.cloudflarestorage.com: no such host"),
			"unreachable"},
	}

	for _, c := range cases {
		got := classifyR2Error(c.err, "tajikshop")
		if !strings.Contains(got, c.want) {
			t.Errorf("%s: classifyR2Error()=%q, бояд %q дошта бошад", c.name, got, c.want)
		}
	}
}

// Паёми хато ҳеҷ гоҳ набояд калидро дар бар гирад — он ба лог ва ба
// `/health` меравад, ки оммавӣ аст.
func TestClassifyR2ErrorHidesTheKey(t *testing.T) {
	const secret = "a1b2c3d4e5f6a1b2c3d4e5f6"
	err := errors.New("api error InvalidAccessKeyId: key " + secret + " does not exist")
	got := classifyR2Error(err, "tajikshop")
	if strings.Contains(got, secret) {
		t.Fatalf("калид ба паём афтод: %q", got)
	}
}

// Бе `R2_PUBLIC_URL` линки расмҳо нопурра мешавад — инро ҷудо месанҷем.
func TestPublicURLSet(t *testing.T) {
	if (&R2Client{publicURL: ""}).PublicURLSet() {
		t.Error("publicURL-и холӣ бояд false диҳад")
	}
	if (&R2Client{publicURL: "   "}).PublicURLSet() {
		t.Error("publicURL аз фосила бояд false диҳад")
	}
	if !(&R2Client{publicURL: "https://cdn.example.com"}).PublicURLSet() {
		t.Error("publicURL-и воқеӣ бояд true диҳад")
	}
}

// Пеш аз санҷиш ҳолат набояд «ok» бошад — вагарна `/health` дурӯғ мегӯяд.
func TestStatusBeforeVerify(t *testing.T) {
	c := &R2Client{status: "not checked"}
	if c.Status() == "ok" {
		t.Error("то санҷиш ҳолат набояд ok бошад")
	}
}
