require 'minitest/autorun'
require 'byebug'
require 'pp'

require 'fileutils'

module TestHelper
    include FileUtils
    TEMP_PATH = File.dirname( File.realpath( __FILE__ ) ) + "/../tmp" 

    def setup_path( path_name )
        base_path = TEMP_PATH + "/" + path_name

        rm_rf base_path
        mkdir_p base_path

        base_path
    end
end

