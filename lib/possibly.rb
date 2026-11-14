# frozen_string_literal: true

# Vendored from https://github.com/ekylibre/possibly (rev 483d1028, fork of
# https://github.com/rap1ds/ruby-possibly), MIT License, Copyright (c) 2014 Mikko Koski.
# Adapted for Ruby 3+ keyword arguments.



def Maybe(value, parent_stack = [], inst_method = nil)
  inst_method ||= ["Maybe", []]
  if value.nil? || (value.is_a?(None))
    None(inst_method, parent_stack)
  else
    value = value.get if value.is_a? Some
    Some.new(value, inst_method, parent_stack)
  end
end

def Some(value, inst_method = nil, parent_stack = [])
  inst_method ||= ["Some", []]

  Maybe(value, inst_method, parent_stack)
end

def None(inst_method = nil, parent_stack = [])
  inst_method ||= ["None", []]
  None.new(inst_method, parent_stack)
end


class Maybe
  def ==(other)
    other.class == self.class
  end

  alias_method :eql?, :==

  def inspect
    to_s
  end

  def is_some?
    false
  end

  def is_none?
    false
  end

  def or_nil
    or_else nil
  end

  protected

    def print_error(msg)
      message =
        if msg
          msg + "\n\n"
        else
          "\n"
        end

      message + print_stack + "\n"
    end

    def print_stack
      longest_method = stack.drop(1).map { |inv| inv.first }.map(&:length).max || 0
      stack.map { |(method, value)|
        method ||= ""
        "#{method.ljust(longest_method)} => #{value}"
      }.join("\n")
    end

    def stack
      @parent_stack + [self_stack]
    end

    def self_stack
      [inst_method, self.inspect]
    end

    def inst_method
      "#{print_method(@inst_method)}"
    end

    def print_method(invocation)
      method, args, block = invocation

      print_method =
        if method == :[]
          args.to_s
        else
          method.to_s
        end

      print_args =
        if method == :[]
          nil
        elsif args.empty?
          nil
        else
          "(#{args.join(', ')})"
        end

      [print_method, print_args].compact.join("")
    end

end

# Represents a non-empty value
class Some < Maybe
  def initialize(value, inst_method = nil, parent_stack = [])
    @value = value
    @inst_method = inst_method || ["Some.new", []]
    @parent_stack = parent_stack
  end

  def get(*)
    @value
  end

  alias_method :or_else, :get
  alias_method :or_raise, :get

  def catch(*)
    self
  end

  alias_method :recover, :catch

  def is_some?
    true
  end

  def ==(other)
    super && get == other.get
  end

  alias_method :eql?, :==

  def ===(other)
    other && other.class == self.class && @value === other.get
  end

  def method_missing(method_sym, *args, **kwargs, &block)
    Maybe(@value.send(method_sym, *args, **kwargs, &block))
  end

  def to_s
    "Some(#{@value})"
  end

  def fmap(&block)
    Maybe(block.call @value)
  end

  def cata(some:, none:)
    some.call(@value)
  end

  private

    def respond_to_missing?(name, include_all)
      @value.respond_to?(name, include_all) || super
    end


end
# Represents an empty value
class None < Maybe

  class ValueExpectedException < Exception; end

  def initialize(inst_method = nil, parent_stack = [])
    @inst_method = inst_method || ["None.new", []]
    @parent_stack = parent_stack
  end

  def get
    msg ||= "`get` called to None. A value was expected."
    raise ValueExpectedException.new(print_error(msg))
  end

  def or_else(els = nil)
    block_given? ? yield : els
  end

  def catch(&block)
    block.call
    self
  end

  def recover(els = nil)
    Maybe(block_given? ? yield : els)
  end

  def or_raise(msg_or_exception = "`or_raise` called to None. A value was expected.", msg = nil, print_stack: true)
    exception_object =
      if msg_or_exception.respond_to? :exception
        if msg
          msg_or_exception.exception(msg)
        else
          msg_or_exception.exception
        end
      else
        ValueExpectedException.new(msg_or_exception)
      end

    exception_and_stack =
      if print_stack
        exception_object.exception(print_error(exception_object.message))
      else
        exception_object
      end

    raise exception_and_stack
  end

  def method_missing(method_sym, *args, **_kwargs, &block)
    None([method_sym, args, block], self.stack)
  end

  def respond_to_missing?(_name, _all)
    true
  end

  def to_s
    "None"
  end

  def fmap
    None()
  end

  def is_none?
    true
  end

  def cata(some:, none:)
    none.call
  end

  private

    def extract_opts(args)
      *initial, last = *args

      if last.is_a?(::Hash)
        [last, initial]
      else
        [{}, args]
      end
    end
end
