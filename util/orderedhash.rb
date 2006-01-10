require 'forwardable'
class OrderedHash
  def initialize(alist = [])
    @hash = {}
    @array = []
    alist.each do |key, value|
      self[key] = value
    end
  end
  def []=(key, value)
    @array << key if not @hash.has_key?(key)
    @hash[key] = value
  end
  def keys
    @array.clone
  end
  def values
    collect{ |key, value| value }
  end
  def clear
    @array.clear
    @hash.clear
  end
  def delete(key)
    @array.delete(key)
    return @hash.delete(key)
  end

  extend Forwardable
  def_delegator :@hash, :[]
  def_delegator :@hash, :length
  def_delegator :@hash, :empty?

  include Enumerable
  def each
    @array.each do |key|
      yield key, @hash[key]
    end
  end
end
