# coding: cp932
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'optparse'
require 'mini_magick'

require 'pry'

puts "trimming version.0.2019.05.15.1000\n"

@params = Hash.new
@params[:extension]  = "png"
@params[:suffix]  = "_crop"
opt = OptionParser.new
opt.on('-e', '--extension VALUE') {|val| @params[:extension] = val.encode('utf-8') }
opt.on('-s', '--suffix VALUE') {|val| @params[:suffix] = val.encode('utf-8') }
argv = opt.parse(ARGV)
if argv.length != 5
  puts "usage: triming [options] <target_path> <x> <y> <width> <height>"
  puts " target_path: target path"
  puts " x: x"
  puts " y: x"
  puts " width: width"
  puts " height: height"
  puts " [options] -e : extension. default is 'png'"
  puts "           -s : suffix. default is '_crop'"
  exit
end

@params[:target_path] = argv[0]
@params[:x] = argv[1]
@params[:y] = argv[2]
@params[:width] = argv[3]
@params[:height] = argv[4]

def split_path(filepath)
  # { :path, :file, :extension }
  spath = Hash.new
  m = filepath.match(/^(.+)\/(.*)\.(.*)$/)
  if m.nil?
    raise "異常発生 split_path"
  end
  spath[:path] = m[1]
  spath[:file] = m[2]
  spath[:extension] = m[3]
  spath
end
crop_param = "#{@params[:width]}x#{@params[:height]}+#{@params[:x]}+#{@params[:y]}"
puts crop_param
begin
  Dir.glob("#{@params[:target_path]}/**/*.#{@params[:extension]}") do |image_file|
    next if image_file =~ /#{@params[:suffix]}\./ # 前回処理した物は対象外
    puts image_file
    image = MiniMagick::Image.open(image_file)
    image.crop crop_param # "#{@params[:width]}x#{@params[:height]}+#{@params[:x]}+#{@params[:y]}"
    spath = split_path(image_file)
    outpath = spath[:path] + '/' + spath[:file] + @params[:suffix] + '.' + spath[:extension]
    image.write outpath
  end
  puts 'complete.'
rescue => err
  puts err.message
  # puts $!
  puts $@
  exit
end

