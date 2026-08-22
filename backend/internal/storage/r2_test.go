package storage

import "testing"

// keyFromURL — калиди объектро аз URL-и оммавӣ дуруст ҷудо мекунад.
func TestKeyFromURL(t *testing.T) {
	pub := "https://cdn.example.com"
	cases := []struct {
		name, url, want string
	}{
		{"avatar", "https://cdn.example.com/avatars/abc_123.jpg", "avatars/abc_123.jpg"},
		{"trailing slash public", "https://cdn.example.com/products/x.png", "products/x.png"},
		{"empty", "", ""},
		{"mismatch host", "https://other.com/products/x.png", ""},
		{"exact prefix only", "https://cdn.example.com/", ""},
	}
	for _, c := range cases {
		if got := keyFromURL(pub, c.url); got != c.want {
			t.Errorf("%s: keyFromURL(%q)=%q, want %q", c.name, c.url, got, c.want)
		}
	}
	// publicURL бо slash дар охир низ бояд дуруст кор кунад.
	if got := keyFromURL("https://cdn.example.com/", "https://cdn.example.com/stories/s.mp4"); got != "stories/s.mp4" {
		t.Errorf("trailing-slash publicURL: got %q", got)
	}
}
