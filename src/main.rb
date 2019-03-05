# coding: utf-8

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'optparse'
require 'yaml'
require 'test_runner'
require 'test_reader'

require 'pry'

ENV['INLINEDIR'] = File.dirname(File.expand_path(__FILE__))

# Encoding.default_external = 'utf-8'
# Encoding.default_internal = 'utf-8'

# proxy 環境の場合必須っぽい。なんでか不明
# - 【取り急ぎ】seleniumでハマッたエラー処理
#    http://marinesbeambitious.com/post-5197/
ENV['NO_PROXY']="127.0.0.1" # これ指定しておかないと外側に接続しにいく。
# xpath = "/Pane[@Name=\"デスクトップ 1\"][@ClassName=\"#32769\"]/Window[@Name=\"電卓 ‎- 電卓\"][@ClassName=\"ApplicationFrameWindow\"]/Window[@Name=\"電卓\"][@ClassName=\"Windows.UI.Core.CoreWindow\"]/Group[@ClassName=\"LandmarkTarget\"]/Group[@AutomationId=\"DisplayControls\"][@Name=\"ディスプレイ コントロール\"]/Button[@AutomationId=\"clearButton\"][@Name=\"クリア\"]"
# xpath2 = "電卓 ‎- 電卓"
# xpath3 = "‎" # よーわからんスペースが悪さして変換できない。。。ゲイツバグだな。。。
# xpath4 = "電卓 "
# binding.pry

puts "screen_test version.0.2019.02.04.1200\n"
@params = Hash.new
# @params[:test_path] = 'tests/all_screen_disp.yml'
@params[:url]  = "http://127.0.0.1:4723/"
opt = OptionParser.new
opt.on('-u', '--url VALUE') {|val| @params[:url] = val.encode('utf-8') }
argv = opt.parse(ARGV)
if argv.length != 2
  puts "usage: screen_test <tests_path> <scenario_name>"
  puts " tests_path: tests path"
  puts " scenario_name: scenario name to be executed"
  puts " [options] -u : connection destination of WinAppDriver"
  exit
end
@params[:tests_path] = argv[0]
@params[:scenario_name] = argv[1]
begin
  @params[:test_reader] = TestReader.new(@params[:tests_path])
  runner = TestRunner.new(@params)
  runner.run
  puts 'complete.'
rescue => err
  puts err.message
  # puts $!
  puts $@
  exit
end

