require 'parslet'

class CalcParser < Parslet::Parser
  rule :integer do
    (match('[0-9]').repeat(1)).as(:num)
  end

  rule :factor do
    integer
  end

  rule :term do
    (factor.as(:left) >> term_continuation).as(:bin_op)
  end

  rule :term_continuation do
    (str('*').as(:op) >> factor.as(:right) >> term_continuation).maybe.as(:continuation)
  end

  rule :expr do
    (term.as(:left) >> expr_continuation).as(:bin_op)
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

  def inspect
    "(#{left.inspect} #{op} #{right.inspect})"
  end
end

class Num < ASTNode
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def inspect
    value.inspect
  end
end

class CalcTransform < Parslet::Transform

  rule num: simple(:num) do
    Num.new(num.to_i)
  end

  rule bin_op: subtree(:bin_op) do
    continuation = bin_op[:continuation]
    left = bin_op[:left]
    while continuation
      left = BinOp.new(continuation[:op], left, continuation[:right])
      continuation = continuation[:continuation]
    end
    left
  end
end

parse_tree = CalcParser.new.parse('1+2+3*4*5+6')

puts "parse_tree:\n#{parse_tree.inspect}"
puts "applying transform"
ast = CalcTransform.new.apply(parse_tree)
puts "ast:\n#{ast.inspect}"
