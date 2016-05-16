require 'fileutils'
require 'date'
require 'json'
require 'parallel'

class AccessLog
  @@LOG_FORMAT = %r{^([0-9\.]+) - - \[([0-9]{2})/([a-zA-Z]+)/([0-9]{4}):([0-9]{2}:[0-9]{2}:[0-9]{2}) \+[0-9]{4}\] "(.*?)" ([0-9]+) (.+) "(.*?)" "(.*?)"}

  @@OS_PATTERNS = [
    { name: 'Windows XP',    pattern: /Windows NT 5\.1/ },
    { name: 'Windows Vista', pattern: /Windows NT 6\.0/ },
    { name: 'Windows 7',     pattern: /Windows NT 6\.1/ },
    { name: 'Windows 8',     pattern: /Windows NT 6\.2/ },
    { name: 'Windows 8.1',   pattern: /Windows NT 6\.3/ },
    { name: 'Windows 10',    pattern: /Windows NT 10\.0/ },
    { name: 'Windows',       pattern: /Windows NT/ },
    { name: 'Mac OS X',      pattern: /Mac OS X [_0-9]+/ },
    { name: 'iOS 7',         pattern: /OS 7[_0-9]+ like Mac OS X/ },
    { name: 'iOS 8',         pattern: /OS 8[_0-9]+ like Mac OS X/ },
    { name: 'iOS 9',         pattern: /OS 9[_0-9]+ like Mac OS X/ },
    { name: 'iOS',           pattern: /OS [_0-9]+ like Mac OS X/ },
    { name: 'Android 4.1',   pattern: /Android 4\.1/ },
    { name: 'Android 4.2',   pattern: /Android 4\.2/ },
    { name: 'Android 4.3',   pattern: /Android 4\.3/ },
    { name: 'Android 4.4',   pattern: /Android 4\.4/ },
    { name: 'Android 5.0',   pattern: /Android 5\.0/ },
    { name: 'Android 5.1',   pattern: /Android 5\.1/ },
    { name: 'Android 6.0',   pattern: /Android 6\.0/ },
    { name: 'Android',       pattern: /Android [\.0-9]+/ },
    { name: 'Linux',         pattern: /Linux / }
  ]

  @@BROWSER_PATTERNS = [
    { name: 'IE6',           pattern: /MSIE 6\.0/ },
    { name: 'IE7',           pattern: /MSIE 7\.0/ },
    { name: 'IE8',           pattern: /MSIE 8\.0/ },
    { name: 'IE9',           pattern: /MSIE 9\.0/ },
    { name: 'IE10',          pattern: /MSIE 10\.0/ },
    { name: 'IE11',          pattern: /Trident\/.*rv:11\.0/ },
    { name: 'IE',            pattern: /MSIE [0-9]+\.[0-9]+/ },
    { name: 'Edge',          pattern: /Edge\/[0-9]+\.[0-9]/ },
    { name: 'Chrome',        pattern: /Chrome\/[0-9]+\.[0-9]/ },
    { name: 'Firefox',       pattern: /Firefox\/[0-9]+\.[0-9]/ },
    { name: 'Opera',         pattern: /Opera\/[0-9]+\.[0-9]/ },
    { name: 'Standard',      pattern: /Android.*Version\/[0-9]+\.0.*Safari/ },
    { name: 'Safari',        pattern: /Version\/[0-9]+\.0.*Safari/ }
  ]

  def initialize(file)
    @file = file
    @unknown_list = []
  end

  def each
    File.open(@file) do |f|
      f.each_line do |line|
        cols = line.match(@@LOG_FORMAT)
        next if cols.nil?
        date = Date.strptime(cols[2] + cols[3] + cols[4], '%d%b%Y')
        status = cols[7]
        user_agent = cols[10]
        next if user_agent == '-'
        os = judges_os(user_agent)
        browser = judges_browser(user_agent)
        comb = os + ' + ' + browser
        yield(
        { date: date,
          status: status,
          user_agent: user_agent,
          os: os,
          browser: browser,
          comb: comb
        })
      end
    end
  end

  def analyze
    analyze_data = { 'os'=>{}, 'browser'=>{}, 'comb'=>{}, 'status'=>{}, 'total'=>0 }
    each do |line|
      os = line[:os]
      browser = line[:browser]
      comb = line[:comb]
      status = line[:status]

      add_analyze_data(analyze_data, 'os', os)
      add_analyze_data(analyze_data, 'browser', browser)
      add_analyze_data(analyze_data, 'comb', comb)
      add_analyze_data(analyze_data, 'status', status)

      set_analyze_data(analyze_data, line)
    end
    analyze_data
  end

  def add_analyze_data(analyze_data, type, value)
    analyze_data[type][value] = 0 if analyze_data[type][value].nil?
    analyze_data[type][value] += 1
  end

  def set_analyze_data(analyze_data, line)
    analyze_data['date'] = line[:date] if analyze_data['date'].nil?
    analyze_data['total'] += 1
  end

  def judges(user_agent, patterns)
    patterns.each do |ptn|
      next unless user_agent.match(ptn[:pattern])
      return ptn[:name]
    end
    @unknown_list.push(user_agent)
    'unknown'
  end

  def judges_os(user_agent)
    judges(user_agent, @@OS_PATTERNS)
  end

  def judges_browser(user_agent)
    judges(user_agent, @@BROWSER_PATTERNS)
  end

  def analyze_and_to_json
    JSON.generate(analyze)
  end

  def unknown_list
    @unknown_list.uniq
  end

end

file_pattern = './**/' + (ARGV[0] || 'access*.log')
Dir.mkdir('./middle') unless FileTest.exist?('./middle')
Dir.mkdir('./unkown') unless FileTest.exist?('./unkown')

#Dir.glob(file_pattern).each do |file|
Parallel.each(Dir.glob(file_pattern), in_process: 4) do |file|
  accesslog = AccessLog.new(file)
  analyzed_json = file.gsub(%r{/}, '_').gsub(/\._/, './middle/') + '_analyzed.json'
  open(analyzed_json, 'w') do |f|
    f.puts(accesslog.analyze_and_to_json)
  end
  unknown_list = file.gsub(%r{/}, '_').gsub(/\._/, './unkown/') + 'unknown.lst'
  open(unknown_list, 'w') do |f|
    f.puts(accesslog.unknown_list)
  end
  puts 'complete ' + analyzed_json
end
