require "set"
require "parallel"

module Mastermind
  class Scorer
    def initialize
      @cache = {}
    end

    def score(pattern, guess)
      @cache["#{pattern}:#{guess}"] ||= begin
        score = ""
        check_pattern = pattern.dup
        guess_chars = guess.chars

        guess_chars.each_with_index do |guess_color, index|
          next unless check_pattern[index] == guess_color
          score << "B"
          guess_chars[index] = " "
          check_pattern[index] = " "
        end

        guess_chars.each do |guess_color|
          match_index = check_pattern.index(guess_color)
          next unless match_index && guess_color != " "
          score << "W"
          check_pattern[match_index] = " "
        end

        score
      end
    end
  end

  class Runner
    NUMBERS = %w[0 1 2 3 4 5 6 7 8 9].freeze
    PATTERN_SIZE = 5
    POSSIBLE_PATTERNS = NUMBERS.permutation(PATTERN_SIZE).map{|f| f.join }

    def initialize(scorer: Scorer.new)
      @scorer = scorer
    end

    def run
      unused_patterns = POSSIBLE_PATTERNS.dup
      potential_patterns = Set.new(unused_patterns)
      guess_count = 1
      guess = ''
      while true do

        puts "Add guess"
        guess = gets.chomp

        puts "Add score"
        score = gets.chomp

        if score == "BBBB"
          puts "correct! winner in #{guess_count}"
          break
        end

        puts "score: #{score}"

        unused_patterns.reject! { |pattern| pattern == guess }

        potential_patterns.reject! do |potential_pattern|
          @scorer.score(guess, potential_pattern) != score
        end
        unless potential_patterns.count > 3000
          # generate new guess
          possible_guesses = []
            possible_guesses = Parallel.map(unused_patterns, in_processes: 8) do |possible_guess|
            highest_hit_count = potential_patterns.each_with_object(Hash.new(0)) do |potential_pattern, counts|
              counts[@scorer.score(potential_pattern, possible_guess)] += 1
            end.values.max || 0
            p possible_guess

            membership_value = potential_patterns.include?(possible_guess) ? 0 : 1

            [highest_hit_count, membership_value, possible_guess]
          end
          guess = possible_guesses.min.last
          guess_count += 1
          p guess
        end
      end
    end
  end
end
