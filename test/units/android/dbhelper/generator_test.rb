#!/usr/bin/env ruby

require_relative "../../../test_helper"
require 'minitest/autorun'
require 'byebug'
require 'pp'

require 'android/dbhelper/generator'

class TestAndroidDbHelperGenerator < Minitest::Test
    include TestHelper

    def test_create_table
        base_path = setup_path( "create_table" )

        generator = Android::Dbhelper::Generator.declare do
            create_table( :ParentTable ) do
                primary_key :id
                one_to_many :TestTable
            end

            create_table( :TestTable ) do
                primary_key :id
                String :abcdef, :null=>false, :has_query_method=>true
                Integer :intValue, :has_query_method=>true
                Float :flatValue
                Double :doubleValue
                DateTime :dateValue
                Blob :blobValue
                Short :shortValue

                many_to_one :ParentTable

                many_to_many :TagTable
            end

            create_table( :TagTable ) do
                primary_key :id
                many_to_many :TestTable
            end

            create_table( :TagTableTestTable ) do
                primary_key :id
                Integer :tagTableId
                Integer :testTableId 
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

    def test_classname_suffix
    end
end
