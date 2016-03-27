require 'json'

class Matrix

  def initialize row_label, col_label
    @row_label = row_label
    @col_label = col_label
    @ary = Array.new(row_label.size+1){Array.new(col_label.size+1, 0)}
  end

  def add date, name, value
    x = @row_label.index(date)
    y = @col_label.index(name)
    @ary[x][y] += value
    @ary[x][@col_label.size] += value
    @ary[@row_label.size][y] += value
    @ary[@row_label.size][@col_label.size] += value
  end

  def add_cols date, cols
    cols.each{|key, value|
      self.add(date, key, value)
    }
  end

  def get_total_access
    @ary[@row_label.size][@col_label.size]
  end

  def create_pie_data
    @col_label.reduce([]){|pie_data, name|
      y = @col_label.index(name)
      access = @ary[@row_label.size][y]
      total  = @ary[@row_label.size][@col_label.size]
      pie_data.push({label:name, value:(access*100.0/total).round(2), access:access})
    }
  end

  def create_line_data
    {
      labels:@row_label,
      datasets:@col_label.reduce([]){|datasets, name|
        datasets.push({
          label:name,
          data:@row_label.reduce([]){|data, date|
            x = @row_label.index(date)
            y = @col_label.index(name)
            access = @ary[x][y]
            total = @ary[x][@col_label.size]
            data.push((access*100.0/total).round(2))
          }
        })
      }
    }
  end

  def sort!
    @col_label.sort_by!.with_index{|col, y|
      -@ary[@row_label.size][y]
    }
    @ary.each{|row|
      row.sort_by!.with_index{|col, y|
        @col_label.size > y ? -@ary[@row_label.size][y] : 0
      }
    }
    self
  end

  def output_csv file_name
    open(file_name, "w") {|f|
      f.puts("," + @col_label.join(",") + ",total")
      @ary.each_with_index{|row, index|
        label = index < @row_label.size ? @row_label[index] : "total"
        f.puts(label + "," + row.join(","))
      }
    }
  end

end

file_pattern = "./middle/*_analyzed.json"

date_labels = []
os_labels = []
browser_labels = []
comb_labels = []
Dir.glob(file_pattern).each{|json|
  middle = open(json) {|json_data|JSON.load(json_data)}
  date_labels.push(middle["date"])
  os_labels      = os_labels      | middle["os"].keys
  browser_labels = browser_labels | middle["browser"].keys
  comb_labels    = comb_labels    | middle["comb"].keys
}
date_labels.uniq!.sort!

os_mtx      = Matrix.new(date_labels, os_labels)
browser_mtx = Matrix.new(date_labels, browser_labels)
comb_mtx    = Matrix.new(date_labels, comb_labels)

Dir.glob(file_pattern).each{|json|
  middle = open(json) {|json_data|JSON.load(json_data)}
  os_mtx.add_cols(middle["date"], middle["os"])
  browser_mtx.add_cols(middle["date"], middle["browser"])
  comb_mtx.add_cols(middle["date"], middle["comb"])
}

os_mtx.sort!.output_csv "os_analytics.csv"
browser_mtx.sort!.output_csv "browser_analytics.csv"
comb_mtx.sort!.output_csv "comb_analytics.csv"

pie = {
  total:  os_mtx.get_total_access,
  os:     os_mtx.create_pie_data,
  browser:browser_mtx.create_pie_data,
  comb:   comb_mtx.create_pie_data,
}
line = {
  os:     os_mtx.create_line_data,
  browser:browser_mtx.create_line_data,
  comb:   comb_mtx.create_line_data,
}

analytics = {pie:pie, line:line}
open("./graphData.json", "w") {|f|
  f.puts(JSON.generate(analytics))
}
