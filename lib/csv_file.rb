class CsvFile
  attr_reader :path, :collection, :errors
  attr_accessor :encoding
  
  def initialize path, colsep = ';', header_lines = 0
    @errors = []
    
    @path = path
    @colsep = colsep
    @header_lines = header_lines
  end
  
  def open
    @file = File.readable?(@path) ? File.open(@path, "r") : false
    @file.rewind
  end
  
  def skip_header_lines
    if @header_lines
      @header_lines.times { readline }
    end
  end
  
  def load_lines count = 1, skip_header = false
    @file.rewind
    if skip_header
      skip_header_lines
    end
    @lines = []
    count.times do
      row = readline
      @lines << row if row && !row.empty?
    end
    @lines
  end
  
  def each skip_header = false
    @file.rewind
    if skip_header
      skip_header_lines
    end
    while row = readline
      yield row
    end
  end
  
  def readline
    line = @file.readline
    if @encoding
      begin
        line = Iconv.conv('utf-8', @encoding, line)
      rescue
      end
    end
    
    line = FasterCSV.parse_line(line, :col_sep => @colsep)
    return line
  end
  
  def loaded?
    @file ? true : false
  end
  
  def same_count_of_columns?
    counts = @lines.map { |r| r.size }
    counts.min == counts.max ? true : false
  end
  
  def count_of_columns
    counts = @lines.map { |r| r.size }
    counts.max
  end
  
  def column_count
    count_of_columns
  end
  
  def method_missing name, *args
    @file.send(name, *args)
  end
  
  protected
  
  def check_collection
    raise("Collection is empty: Please call fetch before accessing the collection") unless @lines
  end
end