require 'bson'

if ARGV[0] then
	num = ARGV[0].to_i
else
	num = 1
end

(1..num).each do
	puts BSON::ObjectId.new
end