#!/usr/bin/env ruby
require 'test/unit'
require 'byebug'
require 'pp'

require File.dirname(__FILE__) + "/../../test_helper.rb"

require 'android/dbhelper/generator'

class TestAndroidDbHelperGenerator < Test::Unit::TestCase
    def test_create_table
        generator = Android::Dbhelper::Generator.declare do
            create_table( :TestTable ) do
                primary_key :id
                String :abcdef, :null=>false
            end
        end

        pp generator

        assert !generator.tables[:TestTable].nil?
    end
end
