require 'rouge'

module Rouge
  module Tokens
    def self.token(name, shortname, &b)
      tok = Token.make_token(name, shortname, &b)
      const_set(name, tok)
    end

    SHORTNAME = 'z'

    token :EntySec, SHORTNAME do
      token :Prompt, "#{SHORTNAME}p"
      token :Error, "#{SHORTNAME}e"
      token :Good, "#{SHORTNAME}g"
      token :Status, "#{SHORTNAME}s"
      token :Warning, "#{SHORTNAME}w"
      token :Info, "#{SHORTNAME}i"
    end
  end

  module Lexers
    class EntySecConsoleLanguage < Rouge::RegexLexer
      title 'EntySec Console'
      tag 'entysec'
      desc 'EntySec Console Highlighter'
      filenames []
      mimetypes []

      def self.keywords
        @keywords ||= Set.new %w()
      end

      state :whitespace do
        rule %r/\s+/, Text
      end

      state :root do
        mixin :whitespace

        rule %r{^(pwny:)}, Text, :pwny_prompt
        rule %r{^\[-\]}, Tokens::EntySec::Error
        rule %r{^\[\+\]}, Tokens::EntySec::Good
        rule %r{^\[\*\]}, Tokens::EntySec::Status
        rule %r{^\[\!\]}, Tokens::EntySec::Warning
        rule %r{^(\[i\]|\[\?\]|\[>\])}, Tokens::EntySec::Info
        rule %r{^(\[)}, Text, :hsf_prompt
        rule %r{^(\()}, Text, :regular_prompt
        rule %r{.+}, Text
      end

      state :regular_prompt do
        mixin :whitespace

        rule %r{ghost|seashell}, Tokens::EntySec::Prompt
        rule %r{:}, Punctuation
        rule %r{[.\w/-]+}, Tokens::EntySec::Error
        rule %r{\)}, Punctuation
        rule %r{>}, Punctuation, :pop!
      end

      state :hsf_prompt do
        mixin :whitespace

        rule %r{hsf\d?}, Tokens::EntySec::Warning
        rule %r{exploit|auxiliary|post}, Text
        rule %r{:}, Punctuation
        rule %r{\]}, Punctuation
        rule %r{[.\w/-]+}, Tokens::EntySec::Error
        rule %r{>}, Punctuation, :pop!
      end

      state :pwny_prompt do
        mixin :whitespace

        rule %r{(/[\w/]*)(?=\s)}, Tokens::EntySec::Prompt
        rule %r{(\w+)}, Tokens::EntySec::Status
        rule %r{\$|\#}, Punctuation, :pop!
      end
    end
  end
end
