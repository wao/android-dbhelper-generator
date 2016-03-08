require 'android/dbhelper/schema_generator'
require 'erb'
require 'fileutils'
require 'simple_assert'
require 'android/dbhelper/relation'
require 'android/dbhelper/column'

module Android; end
module Android::Dbhelper; end


module Android
    module Dbhelper
        class Generator
            attr_reader :tables

            class TypeInfo
                attr_reader :script_type, :db_type, :java_type, :type_in_name

                def initialize( script_type, db_type, java_type, type_in_name )
                    tm_assert{ script_type }
                    @script_type = script_type
                    @db_type = db_type || @script_type.to_s
                    @java_type = java_type || @script_type.to_s
                    @type_in_name = type_in_name || @java_type.to_s
                end

                INTTYPE = [ Integer, Long, Short ]

                def type_class
                    if INTTYPE.include? @script_type
                        :integer
                    else
                        if @script_type == String
                            :string
                        else
                            raise "#{@script_type} doesn't support query method"
                        end
                    end
                end

                STRING_MODIFIERS = { :integer=>"%d", :string=>"\\\"%s\\\"" }
                STRING_METHODS = { :integer=>"", :string=>"" }

                def string_modifier
                    STRING_MODIFIERS[type_class]
                end

                def string_method
                    STRING_METHODS[type_class] 
                end
            end

            def self.define_type( script_type, db_type = nil, java_type = nil, type_in_name = nil )
                @type_map ||= {}
                @type_map[ script_type ] = TypeInfo.new( script_type, db_type, java_type, type_in_name )
            end

            def self.type_info( script_type )
                ret = @type_map[ script_type ]
                if ret.nil?
                    byebug
                end

                tm_assert{ ret }
                ret
            end

            define_type Integer, "INTEGER"
            define_type String, "TEXT"
            define_type Long, "INTEGER"
            define_type Double, "DOUBLE"
            define_type Blob, "Blob", "byte[]", "Blob"
            define_type Float, "FLOAT"
            define_type Short, "SMALLINT"
            define_type DateTime, "INTEGER", "Date"
            define_type Boolean, "SMALLINT"



            class Table
                attr_reader :name, :schema, :options
                attr_accessor :generator

                def initialize( name, schema, options = {} )
                    @name = name
                    @schema = schema
                    @options = options
                    @relations = []
                end

                Template_Table = File.read( File.dirname( __FILE__ ) + "/../../../res/erb/table.erb" )
                Render_Table = ERB.new(Template_Table)

                attr_reader :java_package_name

                def relations
                    @schema.relations
                end

                def file_path(base_path)
                    path = base_path + "/" + @java_package_name.gsub( ".", "/" ) 
                    FileUtils.mkdir_p path
                    path
                end

                def generate_to( path, java_package_name, options)
                    @java_package_name = java_package_name

                    relations.each do |r|
                        r.table = self
                    end

                    File.open( file_path(path) + "/" + java_class_name.to_s + ".java", "w" ).write( dump( Render_Table.result(binding) ) )
                end

                def dump(str)
                    puts str
                    str
                end

                def table_name
                    name
                end

                def columns
                    schema.columns.map { |col| Column.new(col) }      
                end

                def columns_has_query_method
                    columns.select { |c| c.has_query_method? }
                end

                def column_name_list
                    schema.columns.map { |col| '"' + col[:name].to_s + '"' }.join(',')
                end

                def java_class_name
                    if @class_name.nil?
                        @class_name = name.to_s 
                        if generator.nil?
                            byebug
                        end
                        if generator.classname_suffix
                            @class_name = "#{@class_name}#{generator.classname_suffix}"
                        end
                    end

                    @class_name
                end

                def date_field_exist?
                    schema.columns.each do |col|
                        if col[:type] == DateTime
                            return true
                        end
                    end

                    false
                end

                def many_to_many_sql( remote_table_name )
                    remote_table = generator.get_table( remote_table_name )
                    column_def = remote_table.columns.map{ |column| "#{remote_table.table_name}.#{column.column_name} as #{column.column_name}" }.join(",")
                    "select #{column_def} from #{table_name}, #{remote_table_name} where #{table_name}.id = #{remote_table.table_name}.#{table_name.downcase}Id"
                end
            end

            class Sqlite
                def serial_primary_key_options
                    {:type=>Integer, :primary_key=>true}
                end
            end

            class EvalClass
            end

            def self.load(file_path)
                EvalClass.instance_eval( File.read(file_path) )
            end

            attr_reader :tables

            def initialize(&block)
                @tables={}
                @db = Sqlite.new
                instance_exec(nil, &block)
            end

            def get_table( table_name )
                ret = @tables[ table_name ]
                tm_assert{ ret }
                ret 
            end

            def self.declare(&block)
                Android::Dbhelper::Generator.new(&block)
            end

            def classname_suffix(str=nil)
                if str.nil?
                    @classname_suffix
                else
                    @classname_suffix = str
                    self
                end
            end

            def create_table(name,options={},&block)
                @tables[name] = Table.new( name, Android::Dbhelper::Schema::Generator.new(@db, &block), options )
            end

            def generate_to(path, java_package_name, options = {})
                @tables.each_pair do |name,table|
                    table.generator = self
                end

                @tables.each_pair do |name,table|
                    table.generate_to( path, java_package_name, options )
                end
            end
        end
    end
end

module Android 
    def self.dbschema(&block)
        Dbhelper::Generator.declare(&block)
    end
end
