require "./token"

module Crylox
  class RuntimeException < Exception
    property token

    def initialize(@token : Token, message : String)
      super(message)
    end
  end
end
