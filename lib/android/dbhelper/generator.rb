require 'android/dbhelper/schema_generator'

module Android; end
module Android::Dbhelper; end

class Android::Dbhelper::Generator
  VERSION = "1.0.0"

  attr_reader :tables

  Table = Struct.new( :name, :schema, :options )
  class Sqlite
        def serial_primary_key_options
            {}
        end
  end


  def initialize(block)
      @tables={}
      @db = Sqlite.new
      instance_exec(nil, &block)
  end

  def self.declare(&block)
      Android::Dbhelper::Generator.new(block)
  end

  def create_table(name,options={},&block)
      @tables[name]= Table.new( Android::Dbhelper::Schema::Generator.new(@db, &block), options )
  end
end
