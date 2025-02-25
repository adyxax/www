package main

import (
	"slices"
	"testing"
)

func TestNormalizeWords(t *testing.T) {
	testCases := []struct {
		name     string
		input    []string
		expected []string
	}{
		{"simple", []string{"one", "two", "three"}, []string{"one", "three", "two"}},
		{"duplicates", []string{"one", "one", "two", "one", "three", "two"}, []string{"one", "three", "two"}},
	}
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			valid := normalizeWords(tc.input)
			if slices.Compare(valid, tc.expected) != 0 {
				t.Errorf("got %v, want %v", valid, tc.expected)
			}
		})
	}
}

func TestScoreIndex(t *testing.T) {
	testCases := []struct {
		name     string
		input    []string
		index    []string
		expected int
	}{
		{"simple", []string{"one", "two", "three"}, []string{"one", "three", "two"}, 3},
		{"duplicates", []string{"one", "one"}, []string{"one", "three", "two"}, 2},
		{"none", []string{"one", "two"}, []string{"three", "four", "five"}, 0},
	}
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			valid := scoreIndex(tc.input, tc.index)
			if valid != tc.expected {
				t.Errorf("got %v, want %v", valid, tc.expected)
			}
		})
	}
}
