module BSON
    class ObjectId

      def converted_to_s
        @data.map {|e| v=e.to_s(16); v.size == 1 ? "0#{v}" : v }.join
      end

      # Monkey patching to_json so it will return
      # ObjectId as json and not as a simple string containg the oid
      def to_json(*a)
        "{\"$oid\": \"#{converted_to_s}\"}"
      end

      # Monkey patching as_json so it will return
      # ObjectId as json and not as a simple string containg the oid
      def as_json(options ={})
        {"$oid" => converted_to_s}
      end

    end
end