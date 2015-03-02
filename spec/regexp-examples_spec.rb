RSpec.describe Regexp, "#examples" do
  def self.examples_exist_and_match(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        regexp_examples = regexp.examples(max_group_results: 999)

        expect(regexp_examples).not_to be_empty, "No examples were generated for regexp: /#{regexp.source}/"
        regexp_examples.each { |example| expect(example).to match(/\A(?:#{regexp.source})\z/) }
        # Note: /\A...\z/ is used to prevent misleading examples from passing the test.
        # For example, we don't want things like:
        # /a*/.examples to include "xyz"
        # /a|b/.examples to include "bad"
      end
    end
  end

  def self.examples_raise_illegal_syntax_error(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        expect{regexp.examples}.to raise_error RegexpExamples::IllegalSyntaxError
      end
    end
  end

  def self.examples_are_empty(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        expect(regexp.examples).to be_empty
      end
    end
  end

  context 'returns matching strings' do
    context "for basic repeaters" do
      examples_exist_and_match(
        /a/,   # "one-time repeater"
        /a*/,  # greedy
        /a*?/, # reluctant (non-greedy)
        /a*+/, # possesive
        /a+/,
        /a+?/,
        /a*+/,
        /a?/,
        /a??/,
        /a?+/,
        /a{1}/,
        /a{1}?/,
        /a{1}+/,
        /a{1,}/,
        /a{1,}?/,
        /a{1,}+/,
        /a{,2}/,
        /a{,2}?/,
        /a{,2}+/,
        /a{1,2}/,
        /a{1,2}?/,
        /a{1,2}+/
      )
    end

    context "for basic groups" do
      examples_exist_and_match(
        /[a]/,
        /(a)/,
        /a|b/,
        /./
      )
    end

    context "for complex char groups (square brackets)" do
      examples_exist_and_match(
        /[abc]/,
        /[a-c]/,
        /[abc-e]/,
        /[^a-zA-Z]/,
        /[\w]/,
        /[]]/, # TODO: How to suppress annoying warnings on this test?
        /[\]]/,
        /[\\]/,
        /[\\\]]/,
        /[\n-\r]/,
        /[\-]/,
        /[-abc]/,
        /[abc-]/,
        /[%-+]/, # This regex is "supposed to" match some surprising things!!!
        /['-.]/, # Test to ensure no "infinite loop" on character set expansion
        /[[abc]]/, # Nested groups
        /[[[[abc]]]]/,
        /[[a][b][c]]/,
        /[[a-h]&&[f-z]]/, # Set intersection
        /[[a-h]&&ab[c]]/, # Set intersection
        /[[a-h]&[f-z]]/, # NOT set intersection
      )
    end

    context "for complex multi groups" do
      examples_exist_and_match(
        /(normal)/,
        /(?:nocapture)/,
        /(?<name>namedgroup)/,
        /(?<name>namedgroup) \k<name>/
      )
    end

    context "for escaped characters" do
      all_letters = Array('a'..'z') | Array('A'..'Z')
      special_letters = %w(b c g p u x z A B C G M P Z)
      valid_letters = all_letters - special_letters

      valid_letters.each do |char|
        backslash_char = "\\#{char}"
        examples_exist_and_match( /#{backslash_char}/ )
      end
      examples_exist_and_match( /[\b]/ )
    end

    context "for backreferences" do
      examples_exist_and_match(
        /(repeat) \1/,
        /(ref1) (ref2) \1 \2/,
        /((ref2)ref1) \1 \2/,
        /((ref1and2)) \1 \2/,
        /(one)(two)(three)(four)(five)(six)(seven)(eight)(nine)(ten) \10\9\8\7\6\5\4\3\2\1/,
        /(a?(b?(c?(d?(e?)))))/,
        /(a)? \1/,
        /(a|(b)) \2/,
        /([ab]){2} \1/ # \1 should always be the LAST result of the capture group
      )
    end

    context "for escaped octal characters" do
      examples_exist_and_match(
        /\10\20\30\40\50/,
        /\177123/ # Should work for numbers up to 177
      )
    end

    context "for complex patterns" do
      # Longer combinations of the above
      examples_exist_and_match(
        /https?:\/\/(www\.)github\.com/,
        /(I(N(C(E(P(T(I(O(N)))))))))*/,
        /[\w]{1}/,
        /((a?b*c+)) \1/,
        /((a?b*c+)?) \1/,
        /a|b|c|d/,
        /a+|b*|c?/,
        /one|two|three/
      )
    end

    context "for illegal syntax" do
      examples_raise_illegal_syntax_error(
        /(?=lookahead)/,
        /(?!neglookahead)/,
        /(?<=lookbehind)/,
        /(?<!neglookbehind)/,
        /\bword-boundary/,
        /no\Bn-word-boundary/,
        /start-of\A-string/,
        /start-of^-line/,
        /end-of\Z-string/,
        /end-of\z-string/,
        /end-of$-line/,
        /(?<name> ... \g<name>*)/
      )
    end

    context "ignore start/end anchors if at start/end" do
      examples_exist_and_match(
        /\Astart/,
        /\Glast-match/,
        /^start/,
        /end$/,
        /end\z/,
        /end\Z/
      )
    end

    context "for named properties" do
      examples_exist_and_match(
        /\p{L}/,
        /\p{Space}/,
        /\p{AlPhA}/, # Checking case insensitivity
        /\p{^Ll}/
      )

    end

    context "for control characters" do
      examples_exist_and_match(
        /\ca/,
        /\cZ/,
        /\c9/,
        /\c[/,
        /\c#/,
        /\c?/,
        /\C-a/,
        /\C-&/
      )
    end

    context "for escape sequences" do
      examples_exist_and_match(
        /\x42/,
        /\x1D/,
        /\x3word/,
        /#{"\x80".force_encoding("ASCII-8BIT")}/
      )
    end

    context "for unicode sequences" do
      examples_exist_and_match(
      /\u6829/,
      /\uabcd/,
      /\u{42}word/
      )
    end

    context "for empty character sets" do
      examples_are_empty(
        /[^\d\D]/,
        /[^\w\W]/,
        /[^\s\S]/,
        /[^\h\H]/,
        /[^\D0-9]/,
        /[^\Wa-zA-Z0-9_]/,
        /[^\d\D]+/,
        /[^\d\D]{2}/,
        /[^\d\D]word/
      )
    end

    context "for comment groups" do
      examples_exist_and_match(
        /a(?#comment)b/,
        /a(?#ugly backslashy\ comment\\\))b/
      )
    end

    context "for POSIX groups" do
      examples_exist_and_match(
        /[[:alnum:]]/,
        /[[:alpha:]]/,
        /[[:blank:]]/,
        /[[:cntrl:]]/,
        /[[:digit:]]/,
        /[[:graph:]]/,
        /[[:lower:]]/,
        /[[:print:]]/,
        /[[:punct:]]/,
        /[[:space:]]/,
        /[[:upper:]]/,
        /[[:xdigit:]]/,
        /[[:word:]]/,
        /[[:ascii:]]/,
        /[[:^alnum:]]/ # Negated
      )
    end

    context "exact examples match" do
      # More rigorous tests to assert that ALL examples are being listed
      context "default config options" do
        # Simple examples
        it { expect(/[ab]{2}/.examples).to eq ["aa", "ab", "ba", "bb"] }
        it { expect(/(a|b){2}/.examples).to eq ["aa", "ab", "ba", "bb"] }
        it { expect(/a+|b?/.examples).to eq ["a", "aa", "aaa", "", "b"] }

        # a{1}? should be equivalent to (?:a{1})?, i.e. NOT a "non-greedy quantifier"
        it { expect(/a{1}?/.examples).to eq ["", "a"] }
      end

      context "backreferences and escaped octal combined" do
        it do
          expect(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)? \10\9\8\7\6\5\4\3\2\1/.examples)
            .to eq ["abcdefghi \x08ihgfedcba", "abcdefghij jihgfedcba"]
        end
      end

      context "max_repeater_variance config option" do
        it do
          expect(/a+/.examples(max_repeater_variance: 5))
            .to eq %w(a aa aaa aaaa aaaaa aaaaaa)
        end
        it do
          expect(/a{4,8}/.examples(max_repeater_variance: 0))
            .to eq %w(aaaa)
        end
      end

      context "max_group_results config option" do
        it do
          expect(/\d/.examples(max_group_results: 10))
            .to eq %w(0 1 2 3 4 5 6 7 8 9)
        end
      end

      context "case insensitive" do
        it { expect(/ab/i.examples).to eq %w(ab aB Ab AB) }
        it { expect(/a+/i.examples).to eq %w(a A aa aA Aa AA aaa aaA aAa aAA Aaa AaA AAa AAA) }
        it { expect(/([ab])\1/i.examples).to eq %w(aa bb AA BB) }
      end

      context "multiline" do
        it { expect(/./.examples(max_group_results: 999)).not_to include "\n" }
        it { expect(/./m.examples(max_group_results: 999)).to include "\n" }
      end

      context "exteded form" do
        it { expect(/a b c/x.examples).to eq %w(abc) }
        it { expect(/a#comment/x.examples).to eq %w(a) }
        it do
          expect(
            /
              line1 #comment
              line2 #comment
            /x.examples
          ).to eq %w(line1line2)
        end
      end

      context "options toggling" do
        context "rest of string" do
          it { expect(/a(?i)b(?-i)c/.examples).to eq %w{abc aBc}}
          it { expect(/a(?x)   b(?-x) c/.examples).to eq %w{ab\ c}}
          it { expect(/(?m)./.examples(max_group_results: 999)).to include "\n" }
        end
        context "subexpression" do
          it { expect(/a(?i:b)c/.examples).to eq %w{abc aBc}}
          it { expect(/a(?i:b(?-i:c))/.examples).to eq %w{abc aBc}}
          it { expect(/a(?-i:b)c/i.examples).to eq %w{abc abC Abc AbC}}
        end
      end
    end

  end
end
