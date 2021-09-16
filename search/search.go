package main

import (
	"embed"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"regexp"
	"sort"
	"strings"
)

// Variables to customise the search behaviour
const (
	listenStr        = "0.0.0.0:8080"
	titleScore       = 20
	tagsScore        = 10
	descriptionScore = 5
	contentScore     = 1
)

//go:embed index.html search.html
var templatesFS embed.FS

//go:embed index.json
var indexFS embed.FS

// html templates
var searchTemplate = template.Must(template.New("search").ParseFS(templatesFS, "search.html", "index.html"))

// index records
type JsonIndexRecord struct {
	Content     string   `json:"content"`
	Description string   `json:"description"`
	Permalink   string   `json:"permalink"`
	Tags        []string `json:"tags"`
	Title       string   `json:"title"`
}

type SearchIndexRecord struct {
	Title       []string
	Tags        []string
	Description []string
	Content     []string
	Permalink   string
}

var jsonIndex []JsonIndexRecord
var searchIndex []SearchIndexRecord

// The following works on index entries to clean up words : remove case, punctuation, words less than 3 characters
var validWord = regexp.MustCompile(`([a-zA-Z0-9]+)`)

func normalizeWords(words []string) (result []string) {
	sort.Strings(words) // to easily remove duplicates
	lastword := ""
	for i := 0; i < len(words); i++ {
		word := strings.ToLower(validWord.FindString(words[i])) // Get rid of punctuation, would not work well for french apostrophes
		if word == lastword || len(word) < 3 {                  // we remove duplicates and words less than 3 characters
			continue
		}
		result = append(result, word)
	}
	return
}

// The scoring function used by the index
func scoreIndex(words []string, indexWords []string) (score int) {
	for i := 0; i < len(indexWords); i++ {
		for j := 0; j < len(words); j++ {
			if strings.Contains(indexWords[i], words[j]) {
				score++
			}
		}
	}
	return
}

// We need a way to sort by score and get an article Id
type Pair struct {
	Id    int
	Score int
}

type Pairs []Pair

func (p Pairs) Len() int           { return len(p) }
func (p Pairs) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
func (p Pairs) Less(i, j int) bool { return p[i].Score < p[j].Score }

// the template variables
type SearchPage struct {
	Query             string
	SearchTitle       bool
	SearchTags        bool
	SearchDescription bool
	SearchContent     bool
	Results           []JsonIndexRecord
}

// The search handler of the webui
func searchHandler(w http.ResponseWriter, r *http.Request) error {
	p := SearchPage{
		Query: r.FormValue("query"),
	}
	if p.Query != "" && len(p.Query) >= 3 && len(p.Query) <= 64 {
		log.Printf("searching for: %s", p.Query)
		// First we reset the search options status
		p.SearchTitle = r.FormValue("searchTitle") == "true"
		p.SearchTags = r.FormValue("searchTags") == "true"
		p.SearchDescription = r.FormValue("searchDescription") == "true"
		p.SearchContent = r.FormValue("searchContent") == "true"
		// Then we walk the index
		words := normalizeWords(strings.Fields(strings.ToLower(p.Query)))
		scores := make(Pairs, 0)
		for i := 0; i < len(jsonIndex); i++ {
			score := 0
			if p.SearchTitle {
				score = titleScore * scoreIndex(words, searchIndex[i].Title)
			}
			if p.SearchTags {
				score += tagsScore * scoreIndex(words, searchIndex[i].Tags)
			}
			if p.SearchDescription {
				score += descriptionScore * scoreIndex(words, searchIndex[i].Description)
			}
			if p.SearchContent {
				score += contentScore * scoreIndex(words, searchIndex[i].Content)
			}
			if score > 0 {
				scores = append(scores, Pair{i, score})
			}
		}
		// we sort highest scores first
		sort.Sort(scores)
		for i := len(scores) - 1; i >= 0; i-- {
			p.Results = append(p.Results, jsonIndex[scores[i].Id])
		}
	} else {
		// default checkbox values
		p.SearchTitle = true
		p.SearchTags = true
	}
	w.Header().Set("Cache-Control", "no-store, no-cache")
	if err := searchTemplate.ExecuteTemplate(w, "index.html", p); err != nil {
		return newStatusError(http.StatusInternalServerError, err)
	}
	return nil
}

// the environment that will be passed to our handlers
type handlerError interface {
	error
	Status() int
}
type statusError struct {
	code int
	err  error
}

func (e *statusError) Error() string           { return e.err.Error() }
func (e *statusError) Status() int             { return e.code }
func newStatusError(code int, err error) error { return &statusError{code: code, err: err} }

type handler struct {
	h func(w http.ResponseWriter, r *http.Request) error
}

// ServeHTTP allows our handler type to satisfy http.Handler
func (h handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	err := h.h(w, r)
	if err != nil {
		switch e := err.(type) {
		case handlerError:
			log.Printf("HTTP %d - %s", e.Status(), e)
			http.Error(w, e.Error(), e.Status())
		default:
			// Any error types we don't specifically look out for default to serving a HTTP 500
			log.Printf("%s : handler returned an unexpected error : %+v", path, e)
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		}
	}
}

// The main function
func main() {
	if indexFile, err := indexFS.Open("index.json"); err != nil {
		log.Fatal("Failed to open index.json : " + err.Error())
	} else {
		defer indexFile.Close()
		// we decode the jsonIndex
		if err := json.NewDecoder(indexFile).Decode(&jsonIndex); err != nil {
			log.Fatal("Failed to decode index.json : " + err.Error())
		}

		// then build the search index with normalized words
		searchIndex = make([]SearchIndexRecord, len(jsonIndex))
		for i := 0; i < len(jsonIndex); i++ {
			searchIndex[i].Title = normalizeWords(strings.Fields(jsonIndex[i].Title))
			searchIndex[i].Description = normalizeWords(strings.Fields(jsonIndex[i].Description))
			searchIndex[i].Tags = normalizeWords(jsonIndex[i].Tags)
			searchIndex[i].Content = normalizeWords(strings.Fields(jsonIndex[i].Content))
			searchIndex[i].Permalink = jsonIndex[i].Permalink
		}
	}

	http.Handle("/", handler{searchHandler})
	log.Printf("Starting webui on %s", listenStr)
	log.Fatal(http.ListenAndServe(listenStr, nil))
}
