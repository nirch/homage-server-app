
# Assert Options--
# assert( boolean, [message] )	True if boolean
# assert_equal( expected, actual, [message] )
# assert_not_equal( expected, actual, [message] )	True if expected == actual
# assert_match( pattern, string, [message] )
# assert_no_match( pattern, string, [message] )	True if string =~ pattern
# assert_nil( object, [message] )
# assert_not_nil( object, [message] )	True if object == nil
# assert_in_delta( expected_float, actual_float, delta, [message] )	True if (actual_float - expected_float).abs <= delta
# assert_instance_of( class, object, [message] )	True if object.class == class
# assert_kind_of( class, object, [message] )	True if object.kind_of?(class)
# assert_same( expected, actual, [message])
# assert_not_same( expected, actual, [message] )	True if actual.equal?( expected ).
# assert_raise( Exception,... ) {block}
# assert_nothing_raised( Exception,...) {block}	True if the block raises (or doesn't) one of the listed exceptions.
# assert_throws( expected_symbol, [message] ) {block}
# assert_nothing_thrown( [message] ) {block}	True if the block throws (or doesn't) the expected_symbol.
# assert_respond_to( object, method, [message] )	True if the object can respond to the given method.
# assert_send( send_array, [message] )	True if the method sent to the object with the given arguments return true.
# assert_operator( object1, operator, object2, [message] )	Compares the two objects with the given operator, passes if true
 
require_relative "../emuconsole/logic/package"
require_relative "../emuconsole/logic/emuticon"
require "test/unit"
 
class TestEmuConsole < Test::Unit::TestCase

	def setup
    	@num = SimpleNumber.new(2)
  	end
 
  	def teardown
    	## Nothing really
  	end
 
  	def test_simple
    	assert_equal(4, @num.add(2) )
  	end
 
  	def test_simple2
    	assert_equal(4, @num.multiply(2) )
  	end
 
end