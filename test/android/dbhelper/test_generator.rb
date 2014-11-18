gem "minitest"
require "minitest/autorun"
require "android/dbhelper/generator"

module TestAndroid; end
module TestAndroid::TestDbhelper; end

class TestAndroid::TestDbhelper::TestGenerator < Minitest::Test
  def test_sanity
    flunk "write tests or I will kneecap you"
  end
end
