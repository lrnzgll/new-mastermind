package main

import (
	"sort"
	"strings"

	"./filter"
	"./guess"
	"./master"
	"./statistics"
)

var loopCounter int
var exit bool

func allPossibilities(digitNumber int) []string {
	possibilites := make([]string, 0)
	for combination := range generateCombinations("bc", digitNumber) {
		combination = sortString(combination)
		possibilites = append(possibilites, combination)
		possibilites = sliceUniqMap(possibilites)
	}
	return possibilites
}

func sortString(w string) string {
	s := strings.Split(w, "")
	sort.Strings(s)
	return strings.Join(s, "")
}

func sliceUniqMap(s []string) []string {
	seen := make(map[string]struct{}, len(s))
	j := 0
	for _, v := range s {
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		s[j] = v
		j++
	}
	return s[:j]
}

func generateCombinations(alphabet string, length int) <-chan string {
	c := make(chan string)
	go func(c chan string) {
		defer close(c)
		addLetter(c, "", alphabet, length)
	}(c)
	return c
}

func addLetter(c chan string, combo string, alphabet string, length int) {
	if length <= 0 {
		return
	}
	var newCombo string
	for _, ch := range alphabet {
		newCombo = combo + string(ch)
		c <- newCombo
		addLetter(c, newCombo, alphabet, length-1)
	}
}

func main() {
	digitNumber := master.SetNumberOfDigits()
	unusedPatterns := master.SetMultiSlice(digitNumber) //baseArray
	potentialPattern := unusedPatterns                  //currentArray
	possibilities := allPossibilities(digitNumber)
outer:
	for {
		loopCounter++
		statistics.Current(potentialPattern, unusedPatterns)
		guess.AskGuess(loopCounter)
		newGuess := guess.GetGuess()
		score := guess.GetBullsCows(digitNumber)
		unusedPatterns, exit = filter.RemoveGuess(newGuess, unusedPatterns, score, digitNumber)
		if exit == true {
			break outer
		}
		potentialPattern = filter.RejectSlice(newGuess, score, potentialPattern)
		filter.CalculateNextGuess(potentialPattern, unusedPatterns, possibilities)
	}
}
