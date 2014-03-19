module Rook
  def self.linux?
    RUBY_PLATFORM =~ /linux/i
  end
end
