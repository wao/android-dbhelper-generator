require 'erb'
require 'byebug'

module Android
    module Dbhelper

        class Column 
            TEMP_PATH = File.dirname( __FILE__ ) + "/../../../res/erb"

            Render_Column = ERB.new( File.read( TEMP_PATH + "/table_column.erb" ) )
            Render_Query_Method = ERB.new(File.read( TEMP_PATH + "/table_column_query_method.erb" ) )

            DefOpts = { :null=>true, :primary_key=>false, :unique=>false, :index=>false }

            def initialize(col)
                @col = DefOpts.merge col
            end

            def type_info
                ret = Android::Dbhelper::Generator.type_info( @col[:type] )
                raise "Unknown type %s" % @col[:type].to_s if ret.nil?
                ret
            end

            def type_in_name
                type_info.type_in_name
            end

            def java_type
                type_info.java_type
            end

            def java_boxed_type
                case type_info.script_type.to_s.to_sym
                when :Blob
                    "byte[]"
                when :DateTime
                    Date
                else
                    type_info.script_type
                end
            end

            def field_name
                @col[:name].to_s.capitalize
            end

            def string_modifier
                type_info.string_modifier
            end

            def string_method
                type_info.string_method
            end

            def field_method_name
                @col[:name].to_s
            end

            def column_name
                @col[:name].to_s
            end

            def render
                Render_Column.result(binding)
            end

            def render_query_method
                Render_Query_Method.result(binding)
            end

            def null_def
                if @col[:null]
                    nil
                else
                    "NOT NULL"
                end
            end

            def index_def
                if @col[:index]
                    "INDEX"
                else
                    nil
                end
            end

            def primary_key_def
                if @col[:primary_key]
                    if @col[:type] == Integer
                        "PRIMARY KEY AUTOINCREMENT"
                    else
                        "PRIMARY KEY"
                    end
                end
            end

            def default_def
                if !@col[:default].nil?
                    "DEFAULT #{@col[:default]}"
                end
            end

            def unique_def
                if @col[:unique]
                    "UNIQUE"
                else
                    nil
                end
            end


            def col_type
                @col[:type]
            end

            def db_type
                type_info.db_type
            end


            def def_sql
                [ "'" + column_name + "'", db_type, null_def, primary_key_def, default_def, unique_def, index_def ].reject{|e| e.nil? }.join(" ")
            end

            def has_query_method?
                @col[:primary_key] || @col[:has_query_method]
            end
        end
    end
end
