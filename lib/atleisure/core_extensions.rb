module Atleisure
  module CoreExtensions
    def symbolize_keys(hash)
      new_hash = {}
      hash.each{ |key,value| new_hash[key.to_symbol] = value }
      hash
    end

    def symbolize_keys!(hash)
      hash.keys.each do |key|
        hash[(key.to_sym rescue key) || key] = hash.delete(key)
      end
      hash
    end

    def underscore(string)
      string.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end
  end
end