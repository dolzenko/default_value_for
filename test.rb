# Copyright (c) 2008 Phusion
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rubygems'
require 'active_record'
require 'test/unit'
require File.dirname(__FILE__) + '/init'
Dir.chdir(File.dirname(__FILE__))

if RUBY_PLATFORM == "java"
	database_adapter = "jdbcsqlite3"
else
	database_adapter = "sqlite3"
end

File.unlink('test.sqlite3') rescue nil
ActiveRecord::Base.establish_connection(
	:adapter => database_adapter,
	:database => 'test.sqlite3'
)
ActiveRecord::Base.connection.create_table(:numbers, :force => true) do |t|
	t.string :type
	t.integer :number
	t.integer :count, :null => false, :default => 1
end
ActiveRecord::Base.connection.insert("INSERT INTO numbers (number) VALUES (9876)")

class DefaultValuePluginTest < Test::Unit::TestCase
	def define_model_class(name = "TestClass", parent_class_name = "ActiveRecord::Base", &block)
		Object.send(:remove_const, name) rescue nil
		eval("class #{name} < #{parent_class_name}; end", TOPLEVEL_BINDING)
		klass = eval(name, TOPLEVEL_BINDING)
		klass.class_eval(&block) if block_given?
	end
	
	def test_default_value_can_be_passed_as_argument
		define_model_class do
			set_table_name 'numbers'
			default_value_for(:number, 1234)
		end
		object = TestClass.new
		assert_equal 1234, object.number
	end
	
	def test_default_value_can_be_passed_as_block
		define_model_class do
			set_table_name 'numbers'
			default_value_for(:number) { 1234 }
		end
		object = TestClass.new
		assert_equal 1234, object.number
	end
	
	def test_overwrites_db_default
		define_model_class do
			set_table_name 'numbers'
			default_value_for :count, 1234
		end
		object = TestClass.new
		assert_equal 1234, object.count
	end
	
	def test_doesnt_overwrite_values_provided_by_mass_assignment
		define_model_class do
			set_table_name 'numbers'
			default_value_for :number, 1234
		end
		object = TestClass.new(:number => 1, :count => 2)
		assert_equal 1, object.number
	end
	
	def test_doesnt_overwrite_values_provided_by_constructor_block
		define_model_class do
			set_table_name 'numbers'
			default_value_for :number, 1234
		end
		object = TestClass.new do |x|
			x.number = 1
			x.count = 2
		end
		assert_equal 1, object.number
	end
	
	def test_doesnt_overwrite_explicitly_provided_nil_values_in_mass_assignment
		define_model_class do
			set_table_name 'numbers'
			default_value_for :number, 1234
		end
		object = TestClass.new(:number => nil)
		assert_nil object.number
	end
	
	def test_default_values_are_inherited
		define_model_class("TestSuperClass") do
			set_table_name 'numbers'
			default_value_for :number, 1234
		end
		define_model_class("TestClass", "TestSuperClass")
		object = TestClass.new
		assert_equal 1234, object.number
	end
	
	def test_doesnt_set_default_on_saved_records
		define_model_class do
			set_table_name 'numbers'
			default_value_for :number, 1234
		end
		assert_equal 9876, TestClass.find(:first).number
	end
end