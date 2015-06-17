require 'erb'

module Android
    module Dbhelper
        class Relation
            TYPES=[:one_to_many, :many_to_one, :many_to_many, :one_to_one]

            TEMPLATES = TYPES.inject({}) { |memo, t| 
                memo[t]=ERB.new( File.read( File.dirname( __FILE__ ) + "/../../../res/erb/#{t}.erb" ) ) 
                memo
            }

            attr_accessor :table

            def initialize(type, table_name, opts={})
                tm_assert{ TYPES.include? type }
                tm_assert{ table_name }
                @table = nil
                @type = type
                @remote_table_name = table_name
                @opts = opts

                @method_name = @opts[:method_name] ||  decapitalize(@remote_table_name.to_s) + "Reader"
            end

            def render
                @remote_table = @table.generator.get_table( @remote_table_name )
                TEMPLATES[@type].result(binding)
            end

            def remote_class_name
                @remote_table.java_class_name
            end

            def remote_table_name
                @remote_table.table_name
            end

            def method_name
                @method_name 
            end

            def remote_id_field_name
                "id"
            end

            def id_field_name
                "id"
            end

            def decapitalize(val)
                tm_assert{ val.is_a? String }
                val.sub(/^[A-Z]/) { |f| f.downcase }
            end

            def remote_ref_id_field_name
                decapitalize(@table.table_name.to_s) + "Id"
            end

            def ref_id_field_name
                decapitalize(@remote_table_name.to_s) + "Id"
            end

            def join_table
                if @join_table.nil?
                    join_table_name = @table.table_name.to_s + @remote_table.table_name.to_s
                    @join_table = @table.generator.tables[join_table_name.to_sym]
                    
                    if @join_table.nil?
                        join_table_name = @remote_table.table_name.to_s + @table.table_name.to_s
                        @join_table = @table.generator.tables[join_table_name.to_sym]
                    end

                    tm_assert{ @join_table}
                end

                @join_table
            end

            def many_to_many_sql
                column_def = @remote_table.columns.map{ |column| "#{@remote_table.table_name}.#{column.column_name} as #{column.column_name}" }.join(",")

                "select #{column_def} from #{@table.table_name}, #{@remote_table.table_name}, #{join_table.table_name} where %d = #{join_table.table_name}.#{remote_ref_id_field_name} and #{@remote_table.table_name}.id = #{join_table.table_name}.#{ref_id_field_name}"
            end
        end
    end
end
