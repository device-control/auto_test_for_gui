# coding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'selenium-webdriver'
require 'fileutils'

require 'pry'

# Encoding.default_external = 'utf-8'
# Encoding.default_internal = 'utf-8'

class TestRunner
  attr_reader :table_values
  def initialize(params)
    @params = params
    raise "ERROR: not found :scenario_name" unless @params.has_key? :scenario_name
    raise "ERROR: not found :url" unless @params.has_key? :url
    raise "ERROR: not found :test_reader" unless @params.has_key? :test_reader
    test_reader = @params[:test_reader]
    scenario_name = @params[:scenario_name].to_sym
    raise "ERROR: not found scenario_name" unless test_reader.scenarios.has_key? scenario_name
    @scenario = test_reader.scenarios[scenario_name]
    # raise "ERROR: not found :sequences" unless @scenario.has_key? :sequences

    @sequences = test_reader.sequences
    @target_exe_path = "Root" # <-- Root はデスクトップアプリ操作用にすることみたい。
    @capabilities = {
      app: @target_exe_path
    }
    @driver = Selenium::WebDriver.for(
      :remote,
      url: @params[:url],# "http://127.0.0.1:4723/",
      desired_capabilities: @capabilities
    )
    config = @scenario[:config]
    @screenshots_path = config[:screenshots_path] # './screenshots'
    @screenshots_auto = true # デフォルトはtrueで指定されたらそれに従う
    if config.has_key? :screenshots_auto
      @screenshots_auto = config[:screenshots_auto]
    end
    FileUtils.mkdir_p(@screenshots_path)
  end

  def wait_for_app(class_name)
    puts "wait_for_app: " + class_name.encode('cp932')
    driver = nil
    while true
      begin
        driver = @driver.find_element(:class_name, class_name)
        break
      rescue => e
        puts " " + e.message
        sleep 1
      end
    end
    return driver
  end
  
  def wait_for_form(xpath)
    puts "wait_for_form: " + xpath.encode('cp932')
    driver = nil
    while true
      begin
        break if @driver.find_element(:xpath, xpath.encode('cp932')).displayed?
      rescue => e
        puts " " + e.message
      end
      sleep 1
    end
    return driver
  end

  def get_text(xpath)
    binding.pry
    puts "get_text: " + xpath.encode('cp932')
    target = @driver.find_element(:xpath, xpath.encode('cp932') )
    puts target
  end

  # def set_text(xpath, str)
  def set_text(params)
    xpath = params[:xpath]
    str = params[:text]
    puts "set_text: " + xpath.encode('cp932') + ':' + str.encode('cp932')
    # @driver.find_element(:xpath, xpath.encode('cp932') ).send_keys(str.encode('cp932'))
    target = @driver.find_element(:xpath, xpath.encode('cp932') )
    target.send_keys(str.encode('cp932'))
    if params.has_key? :after_key_event
      args = params[:after_key_event].split(/\s*\+\s*/)
      if args.count == 1
        target.send_keys(params[:after_key_event].to_sym)
      else
        target.send_keys(args[0].to_sym,args[1].to_sym)
      end
    end
  end
  
  def click(xpath)
    puts "click: " + xpath.encode('cp932')
    # @driver.find_element(:xpath, xpath.encode('cp932') ).click
    @driver.find_element(:xpath, xpath.encode('cp932') ).click
  end

  def exe_spawn(exe_path)
    # アプリ起動
    # pid = spawn(File::expand_path('../../kaikei-vb2015/bin/Kaikei.exe'))
    puts "exe_spawn: " + exe_path.encode('cp932')
    if exe_path =~ /^\"/
      # ダブルコーテーションで始まるやつは絶対パス
      spawn(exe_path)
    else
      spawn(File::expand_path(exe_path))
    end
  end

  def run()
    @scenario[:sequences].each.with_index(0) do |sequence_name, sequence_index|
      sequence = @sequences[sequence_name.to_sym]
      sequence[:commands].each.with_index(0) do |command, command_index|
        name = command[:name]
        params = command[:params]
        if name == 'exe_spawn'
          exe_spawn(params[:exe_path])
        elsif name == 'wait_for_app'
          wait_for_app(params[:class_name])
        elsif name == 'wait_for_form'
          wait_for_form(params[:xpath])
          # スクリーンショット
          spath = @screenshots_path + '/' + sequence_name
          FileUtils.mkdir_p(spath)
          png_file = format("%03d", command_index) + ".png"
          params[:xpath].match(/@AutomationId=\"(frm.+?)\"/) do |md|
            png_file = format("%03d", command_index) + "_" + md[1] + ".png"
          end
          # 自動キャプチャ有効／無効チェック
          if @screenshots_auto
            @driver.save_screenshot(spath + '/' + png_file)
          end
        elsif name == 'set_text'
          # set_text(params[:xpath], params[:text])
          set_text(params)
        elsif name == 'click'
          click(params[:xpath])
        elsif name == 'sleep'
          sleep (params[:time] / 1000)
        elsif name == 'screenshot'
          spath = @screenshots_path + '/' + sequence_name
          FileUtils.mkdir_p(spath)
          png_file = format("%03d", command_index) + ".png"
          unless params.nil?
            png_file = params[:filepath] if params.has_key? :filepath
          end
          @driver.save_screenshot(spath + '/' + png_file)
        elsif name == 'directory_copy'
          puts "FileUtils.cp_r(#{params[:src]}, #{params[:dst]})"
          FileUtils.cp_r(params[:src], params[:dst])
        elsif name == 'file_copy'
          puts "FileUtils.cp(#{params[:src]}, #{params[:dst]})"
          FileUtils.cp(params[:src], params[:dst])
        elsif name == 'assert_text'
          text = get_text(params[:xpath])
          binding.pry
          puts text
        end
      end
    end
  end
end

    # commands = @params[:test]['contents']['commands']
    # commands.each.with_index(0) do |command,index|
    #   name = command['name']
    #   params = command['params']
    #   if name == 'exe_spawn'
    #     exe_spawn(params['exe_path'])
    #   elsif name == 'wait_for_app'
    #     wait_for_app(params['class_name'])
    #   elsif name == 'wait_for_form'
    #     wait_for_form(params['xpath'])
    #     png_file = "#{index}.png"
    #     params['xpath'].match(/@AutomationId=\"(frm.+?)\"/) do |md|
    #       png_file = format("%03d", index) + "_" + md[1] + ".png"
    #     end
    #     @driver.save_screenshot(@screenshots_path + "/" + png_file)
    #   elsif name == 'set_text'
    #     set_text(params['xpath'], params['text'])
    #   elsif name == 'click'
    #     click(params['xpath'])
    #   end
    # end


