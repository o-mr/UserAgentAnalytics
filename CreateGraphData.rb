require 'json'

class Matrix
  def initialize(row_label, col_label)
    @row_label = row_label
    @col_label = col_label
    @ary = Array.new(row_label.size + 1) { Array.new(col_label.size + 1, 0) }
  end

  def add(date, name, value)
    x = @row_label.index(date)
    y = @col_label.index(name)
    @ary[x][y] += value
    @ary[x][@col_label.size] += value
    @ary[@row_label.size][y] += value
    @ary[@row_label.size][@col_label.size] += value
  end

  def add_cols(date, cols)
    cols.each do |key, value|
      add(date, key, value)
    end
  end

  def total_access
    @ary[@row_label.size][@col_label.size]
  end

  def create_pie_data
    @col_label.reduce([]) do |pie_data, name|
      y = @col_label.index(name)
      access = @ary[@row_label.size][y]
      total  = @ary[@row_label.size][@col_label.size]
      pie_data.push(label: name, value: (access * 100.0 / total).round(2), access: access)
    end
  end

  def create_line_data
    {
      labels: @row_label,
      datasets: @col_label.reduce([]) do |datasets, name|
        datasets.push(label: name,
                      data: @row_label.reduce([]) do |data, date|
                              x = @row_label.index(date)
                              y = @col_label.index(name)
                              access = @ary[x][y]
                              total = @ary[x][@col_label.size]
                              data.push((access * 100.0 / total).round(2))
                            end)
      end
    }
  end

  def sort!
    @col_label.sort_by!.with_index do |_col, y|
      -@ary[@row_label.size][y]
    end
    @ary.each do |row|
      row.sort_by!.with_index do |_col, y|
        @col_label.size > y ? -@ary[@row_label.size][y] : 0
      end
    end
    self
  end

  def output_csv(file_name)
    open(file_name, 'w') do |f|
      f.puts(',' + @col_label.join(',') + ',total')
      @ary.each_with_index do |row, index|
        label = index < @row_label.size ? @row_label[index] : 'total'
        f.puts(label + ',' + row.join(','))
      end
    end
  end
end

file_pattern = './middle/' + (ARGV[0] || '*_analyzed.json')

date_labels = []
os_labels = []
browser_labels = []
comb_labels = []
status_labels = []
Dir.glob(file_pattern).each do |json|
  middle = open(json) { |json_data| JSON.load(json_data) }
  next if middle['date'].nil?
  date_labels.push(middle['date'])
  os_labels      += middle['os'].keys
  browser_labels += middle['browser'].keys
  comb_labels    += middle['comb'].keys
  status_labels  += middle['status'].keys
end
date_labels.uniq!.sort!

os_mtx      = Matrix.new(date_labels, os_labels.uniq!)
browser_mtx = Matrix.new(date_labels, browser_labels.uniq!)
comb_mtx    = Matrix.new(date_labels, comb_labels.uniq!)
status_mtx  = Matrix.new(date_labels, status_labels.uniq!)

Dir.glob(file_pattern).each do |json|
  middle = open(json) { |json_data| JSON.load(json_data) }
  os_mtx.add_cols(middle['date'], middle['os'])
  browser_mtx.add_cols(middle['date'], middle['browser'])
  comb_mtx.add_cols(middle['date'], middle['comb'])
  status_mtx.add_cols(middle['date'], middle['status'])
end

Dir.mkdir('./output') unless FileTest.exist?('./output')
os_mtx.sort!.output_csv './output/os_analytics.csv'
browser_mtx.sort!.output_csv './output/browser_analytics.csv'
comb_mtx.sort!.output_csv './output/comb_analytics.csv'
status_mtx.sort!.output_csv './output/status_analytics.csv'

pie = {
  total:  os_mtx.total_access,
  os:     os_mtx.create_pie_data,
  browser: browser_mtx.create_pie_data,
  comb:   comb_mtx.create_pie_data,
  status: status_mtx.create_pie_data
}
line = {
  os:     os_mtx.create_line_data,
  browser: browser_mtx.create_line_data,
  comb:   comb_mtx.create_line_data,
  status: status_mtx.create_line_data
}

analytics = { pie: pie, line: line }
open('./output/graphData.json', 'w') do |f|
  f.puts(JSON.generate(analytics))
end
