#!/usr/bin/env ruby
require 'test/unit'
require 'byebug'
require 'pp'

require File.dirname(__FILE__) + "/../../test_helper.rb"

require 'android/dbhelper/generator'

class TestAndroidDbHelperGenerator < Test::Unit::TestCase
    include TestHelper

    def test_create_table
        base_path = setup_path( "create_table" )

        generator = Android::Dbhelper::Generator.declare do
            create_table( :TestTable ) do
                primary_key :id
                String :abcdef, :null=>false
                Integer :intValue
                Float :flatValue
                Double :doubleValue
                DateTime :dateValue
                Blob :blobValue
                Short :shortValue
            end
        end

        assert !generator.tables[:TestTable].nil?

        file_path = base_path + "/com/test/TestTable.java" 

        assert !File.exist?(file_path)
        generator.generate_to( base_path, "com.test" )
        assert File.exist?(file_path)
    end

    def test_schema
        base_path = setup_path( "schema" )
        generator = Android.dbschema do
            create_table( :LoadTest ) do
                primary_key :id
            end
        end

        file_path = base_path + "/com/test/LoadTest.java" 
        generator.generate_to( base_path, "com.test" )
        assert File.exist?(file_path)
    end

    def test_load
        base_path = setup_path( "load" )
        generator = Android::Dbhelper::Generator.load( File.dirname(__FILE__) + "/schema.rb" )                                
        pp generator
        file_path = base_path + "/com/test/LoadTest.java" 
        generator.generate_to( base_path, "com.test" )
        assert File.exist?(file_path)
    end
end
