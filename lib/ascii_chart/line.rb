# frozen_string_literal: true

require_relative 'color_map'

module AsciiChart
  class Line
    DEFAULTS = {
      offset: 3,
      format: '%8.2f ',
      height: nil
    }.freeze

    DECREASING_HI = '╮'
    DECREASING_LO = '╰'
    INCREASING_HI = '╯'
    INCREASING_LO = '╭'
    VERTICAL = '│'
    HORIZONTAL = '-'
    INTERSECTION = ' ┼'
    AXIS_MARK =' ┤'
    

    def initialize(series, options = {})
      @series = series
      @options = DEFAULTS.merge(options)
      
      if options[:color]
        if options[:color].is_a?(Symbol)
          # color name
          @color_sequence = COLOR_MAP[options[:color]]
          raise ArgumentError, "Unknown xterm color name `#{options[:color]}`" unless @color_sequence
        elsif options[:color].is_a?(Integer)
          # xterm color number
          raise ArgumentError, "Invalid xterm color number `#{options[:color]}`" unless (0..255).include?(options[:color])
          @color_sequence = COLOR_MAP[options[:color]]
        end
      end  
    end

    def plot
      max = @series.max
      min = @series.min
      interval = (max - min).abs

      @options[:height] ||= interval
      radio = @options[:height].to_f / interval
      offset = @options[:offset]

      intmax = (max * radio).ceil
      intmin = (min * radio).floor
      rows = (intmax - intmin).abs
      width = @series.length + offset

      result = (0..rows).map { [' '] * width }

      (intmin..intmax).each do |y|
        label = @options[:format] % (max - (((y - intmin) * interval).to_f / rows))
        result[y - intmin][[offset - label.length, 0].max] = label
        result[y - intmin][offset - 1] = y == 0 ? INTERSECTION : AXIS_MARK
      end

      highest = (@series.first * radio - intmin).to_i
      result[rows - highest][offset - 1] = colored(INTERSECTION)

      (0...@series.length - 1).each do |x|
        _curr = (@series[x + 0] * radio).round - intmin
        _next = (@series[x + 1] * radio).round - intmin

        if _curr == _next
          result[rows - _curr][x + offset] = colored(HORIZONTAL)
        else
          result[rows - _curr][x + offset] = colored(_curr > _next ? DECREASING_HI : INCREASING_HI)
          result[rows - _next][x + offset] = colored(_curr > _next ? DECREASING_LO : INCREASING_LO)

          ([_curr, _next].min + 1...[_curr, _next].max).each do |y|
            result[rows - y][x + offset] = colored(VERTICAL)
          end
        end
      end

      result.map(&:join).join("\n")
    end

    private
    def colored(symbol)
      if @color_sequence
        @color_sequence + symbol + RESET_COLOR
      else
        symbol
      end
    end
  end
end
