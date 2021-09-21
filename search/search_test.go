package main

import (
	"testing"

	"github.com/stretchr/testify/require"
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
			require.Equal(t, tc.expected, valid)
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
			require.Equal(t, tc.expected, valid)
		})
	}
}
