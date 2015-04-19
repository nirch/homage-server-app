require 'byebug'

module BSON
    class ObjectId
      def to_json(*args)
        to_s.as_json
        byebug
      end
    end
  end