require 'fileutils'
require "date"
require 'json'

class AccessLog

  @@LOG_FORMAT = /^([0-9\.]+) - - \[([0-9]{2})\/([a-zA-Z]+)\/([0-9]{4}):([0-9]{2}:[0-9]{2}:[0-9]{2}) \+[0-9]{4}\] "(.*?)" ([0-9]+) (.+) "(.*?)" "(.*?)"/

  @@OS_PATTERNS = [
    {name:"Windows XP",    pattern:/Windows NT 5\.1/},
    {name:"Windows Vista", pattern:/Windows NT 6\.0/},
    {name:"Windows 7",     pattern:/Windows NT 6\.1/},
    {name:"Windows 8",     pattern:/Windows NT 6\.2/},
    {name:"Windows 8.1",   pattern:/Windows NT 6\.3/},
    {name:"Windows 10",    pattern:/Windows NT 10\.0/},
    {name:"Windows",       pattern:/Windows NT/},
    {name:"Mac OS X",      pattern:/Mac OS X [_0-9]+/},
    {name:"iOS 7",         pattern:/OS 7[_0-9]+ like Mac OS X/},
    {name:"iOS 8",         pattern:/OS 8[_0-9]+ like Mac OS X/},
    {name:"iOS 9",         pattern:/OS 9[_0-9]+ like Mac OS X/},
    {name:"iOS",           pattern:/OS [_0-9]+ like Mac OS X/},
    {name:"Android 4.1",   pattern:/Android 4\.1/},
    {name:"Android 4.2",   pattern:/Android 4\.2/},
    {name:"Android 4.3",   pattern:/Android 4\.3/},
    {name:"Android 4.4",   pattern:/Android 4\.4/},
    {name:"Android 5.0",   pattern:/Android 5\.0/},
    {name:"Android 5.1",   pattern:/Android 5\.1/},
    {name:"Android 6.0",   pattern:/Android 6\.0/},
    {name:"Android",       pattern:/Android [\.0-9]+/},
    {name:"Linux",         pattern:/Linux /},
  ]

  @@BROWSER_PATTERNS = [
    {name:"IE6",           pattern:/MSIE 6\.0/},
    {name:"IE7",           pattern:/MSIE 7\.0/},
    {name:"IE8",           pattern:/MSIE 8\.0/},
    {name:"IE9",           pattern:/MSIE 9\.0/},
    {name:"IE10",          pattern:/MSIE 10\.0/},
    {name:"IE11",          pattern:/Trident\/.*rv:11\.0/},
    {name:"IE",            pattern:/MSIE [0-9]+\.[0-9]+/},
    {name:"Edge",          pattern:/Edge\/[0-9]+\.[0-9]/},
    {name:"Chrome",        pattern:/Chrome\/[0-9]+\.[0-9]/},
    {name:"Firefox",       pattern:/Firefox\/[0-9]+\.[0-9]/},
    {name:"Opera",         pattern:/Opera\/[0-9]+\.[0-9]/},
    {name:"Standard",      pattern:/Android.*Version\/[0-9]+\.0.*Safari/},
    {name:"Safari",        pattern:/Version\/[0-9]+\.0.*Safari/},
  ]

  def initialize(file)
    @file = file
  end

  def analyze
    result = {os:{}, browser:{}, comb:{}, total:0}
    File.open(@file) {|f|
      f.each_line {|line|
        cols = line.match(@@LOG_FORMAT)
        next if cols == nil
        user_agent = cols[9]
        next if user_agent == nil || user_agent == "-"
        result[:date] = Date.strptime(cols[2]+cols[3]+cols[4], '%d%b%Y') if result[:date] == nil
        os = "unknown"
        @@OS_PATTERNS.each{|ptn|
          next if !line.match(ptn[:pattern])
          os = ptn[:name]
          break
        }
        result[:os][os] = 0 if result[:os][os] == nil
        result[:os][os] += 1

        browser = "unknown"
        @@BROWSER_PATTERNS.each{|ptn|
          next if !line.match(ptn[:pattern])
          browser = ptn[:name]
          break
        }
        result[:browser][browser] = 0 if result[:browser][browser] == nil
        result[:browser][browser] += 1

        comb = os + " + " + browser
        result[:comb][comb] = 0 if result[:comb][comb] == nil
        result[:comb][comb] += 1

        result[:total] += 1
      }
    }
    result
  end
end

file_pattern = "./**/access*.log"

Dir.mkdir("./middle") unless FileTest.exist?("./middle")

Dir.glob(file_pattern).each{|file|
    result = AccessLog.new(file).analyze
    open(file.gsub(/[\\\/]/, "_").gsub(/\._/, "./middle/") + "_analyzed.json", "w") {|f|
      f.puts(JSON.generate(result))
    }
    result
}
