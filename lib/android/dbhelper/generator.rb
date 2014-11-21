require 'android/dbhelper/schema_generator'
require 'erb'
require 'fileutils'

module Android; end
module Android::Dbhelper; end


class Android::Dbhelper::Generator
  VERSION = "1.0.0"

  attr_reader :tables

  class Column 
      Template_Column = File.read( File.dirname( __FILE__ ) + "/../../../res/erb/table_column.erb" )
      Render_Column = ERB.new(Template_Column)

      DefOpts = { :null=>true, :primary_key=>false, :unique=>false, :index=>false }

      def initialize(col)
          @col = DefOpts.merge col
      end
#String, Integer, Fixnum, Bignum, Float, Numeric, BigDecimal,
                               #Date, DateTime, Time, File, TrueClass, FalseClass
      TypeMap = { Integer=>"Integer", String=>"String", :Long=>"Long", :Double=>"Double", :Blob=>"Blob", :Float=>"Float", :Short=>"Short", DateTime=>"Date" }

      def field_type_name
          raise "Unknown type %s" % @col[:type].to_s if TypeMap[@col[:type]].nil?
          TypeMap[@col[:type]]
      end

      def field_name
          @col[:name].to_s.capitalize
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
              "PRIMARY KEY AUTOINCREMENT"
          end
      end

      def default_def
          @col[:default]
      end

      def unique_def
          if @col[:unique]
              "UNIQUE"
          else
              nil
          end
      end

      DbTypeMap = { Integer=>"INTEGER", String=>"TEXT", :Long=>"INTEGER", :Double=>"DOUBLE", :Blob=>"BLOB", :Float=>"FLOAT", :Short=>"SMALLINT", DateTime=>"DateTime" }

      def col_type
          @col[:type]
      end

      def db_type
          raise "Unknown type %s" % @col[:type].to_s if DbTypeMap[@col[:type]].nil?
          DbTypeMap[@col[:type]]
      end


      def def_sql
          [ "'" + column_name + "'", db_type, null_def, primary_key_def, default_def, unique_def, index_def ].reject{|e| e.nil? }.join(" ")
      end

  end

  Table = Struct.new( :name, :schema, :options ) do 
      Template_Table = File.read( File.dirname( __FILE__ ) + "/../../../res/erb/table.erb" )
      Render_Table = ERB.new(Template_Table)

      attr_reader :java_package_name

      def file_path(base_path)
          path = base_path + "/" + @java_package_name.gsub( ".", "/" ) 
          FileUtils.mkdir_p path
          path
      end

      def generate_to( path, java_package_name, options)
        @java_package_name = java_package_name
        
        File.open( file_path(path) + "/" + name.to_s + ".java", "w" ).write( dump( Render_Table.result(binding) ) )
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

      def column_name_list
          schema.columns.map { |col| '"' + col[:name].to_s + '"' }.join(',')
      end

      def java_class_name
          name.to_s
      end

      def date_field_exist?
          schema.columns.each do |col|
              if col[:type] == DateTime
                  return true
              end
          end

          false
      end
  end

  class Sqlite
        def serial_primary_key_options
            {:type=>Integer, :primary_key=>true, :auto_increment=>true}
        end
  end

  class EvalClass
  end

  def self.load(file_path)
      EvalClass.instance_eval( File.read(file_path) )
  end


  def initialize(&block)
      @tables={}
      @db = Sqlite.new
      instance_exec(nil, &block)
  end

  def self.declare(&block)
      Android::Dbhelper::Generator.new(&block)
  end

  def create_table(name,options={},&block)
      @tables[name] = Table.new( name, Android::Dbhelper::Schema::Generator.new(@db, &block), options )
  end

  def generate_to(path, java_package_name, options = {})
      @tables.each_pair do |name,table|
          table.generate_to( path, java_package_name, options )
      end
  end
end

module Android 
    def self.dbschema(&block)
        Dbhelper::Generator.declare(&block)
    end
end
