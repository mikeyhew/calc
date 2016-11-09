require 'parslet'

class CalcParser < Parslet::Parser
  rule :integer do
    match('[0-9]').repeat(1)
  end

  rule :term do
    integer
  end

  rule :expr do
    (term.as(:left) >> expr_continuation).as(:expr)
  end

  rule :expr_continuation do
     (str('+').as(:op) >> term.as(:right) >>expr_continuation).maybe.as(:continuation)
  end

  root :expr
end

class ASTNode
end

class BinOp < ASTNode
  attr_reader :op, :left, :right

  def initialize(op, left, right)
    @op = op
    @left = left
    @right = right
  end
end

class Num < ASTNode
  attr_reader :value

  def initialize(value)
    @value = value
  end
end

class CalcTransform < Parslet::Transform
  rule expr: subtree(:expr) do
    continuation = expr[:continuation]
    left = expr[:left]
    while continuation
      left = BinOp.new(continuation[:op], left, continuation[:right])
      continuation = continuation[:continuation]
    end
    left
  end
end



parse_tree = CalcParser.new.parse('1+2+3')

puts "parse_tree:\n#{parse_tree.inspect}"
puts "applying transform"
ast = CalcTransform.new.apply(parse_tree)
puts "ast:\n#{ast.inspect}"
