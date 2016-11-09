require 'parslet'
require 'bigdecimal'

class CalcParser < Parslet::Parser
  rule :num do
    (match('[0-9]').repeat(1)).as(:num)
  end

  rule :primary_expr do
    str('(') >> expr >> str(')') |
    num
  end

  rule :factor do
    (str('-').as(:op) >> primary_expr.as(:right)).as(:un_op) |
    primary_expr
  end

  rule :term do
    (factor.as(:left) >> term_continuation).as(:bin_op)
  end

  rule :term_continuation do
    (match('\*|/').as(:op) >> factor.as(:right) >> term_continuation).maybe.as(:continuation)
  end

  rule :expr do
    (term.as(:left) >> expr_continuation).as(:bin_op)
  end

  rule :expr_continuation do
     (match('\+|-').as(:op) >> term.as(:right) >>expr_continuation).maybe.as(:continuation)
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

class UnaryOp < ASTNode
  attr_reader :op, :right

  def initialize(op, right)
    @op = op
    @right = right
  end

  def inspect
    "(#{op}#{right.inspect})"
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

  rule un_op: {op: simple(:op), right: simple(:right)} do
    UnaryOp.new(op, right)
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

class Visitor
  def visit(node)
    send("visit_#{node.class.name}", node)
  end
end

class Calculator < Visitor
  def visit_Num(node)
    BigDecimal(node.value)
  end

  def visit_BinOp(node)
    visit(node.left).send(node.op, visit(node.right))
  end

  def visit_UnaryOp(node)
    visit(node.right).send("#{node.op}@")
  end

  def repl
    require 'readline'
    loop do
      begin
        line = Readline.readline("calc> ", true)
        break unless line

        ast = CalcTransform.new.apply(CalcParser.new.parse(line))
        puts ast.inspect
        puts visit(ast).to_s('F')
      rescue Interrupt
        puts ''
      rescue Parslet::ParseFailed => failure
        puts failure.cause.ascii_tree
      end
    end
  end

end

# parse_tree = CalcParser.new.parse('1+-2+3*4*5+5-46/5+3/3/4')

# puts "parse_tree:\n#{parse_tree.inspect}"
# puts "applying transform"
# ast = CalcTransform.new.apply(parse_tree)
# puts "ast:\n#{ast.inspect}"
# result = Calculator.new.visit(ast)
# puts "result:\n#{result.to_s('F')}"

Calculator.new.repl
