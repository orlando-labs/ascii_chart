# frozen_string_literal: true

require_relative 'color_map'

module AsciiChart
  class Line
    DEFAULTS = {
      offset: 0,
      format: '%8.2f ',
      height: 5
    }.freeze

    DECREASING_HI = '╮'
    DECREASING_LO = '╰'
    INCREASING_HI = '╯'
    INCREASING_LO = '╭'
    VERTICAL = '│'
    HORIZONTAL = '-'
    INTERSECTION = ' ┼'
    AXIS_MARK = ' ┤'
    BLANK_SPACE = ' '

    AXIS_OFFSET = 2
    
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

      if options[:offset]
        unless options[:offset].is_a?(Integer) && (0..series.size).include?(options[:offset])
          raise ArgumentError, "Axis offset must be a positive integer less or equal to series size"
        end
      end
    end

    def chars
      max = @series.max
      min = @series.min
      interval = (max - min).abs

      rows_count = @options[:height] || (interval.between?(5, 20) ? interval.ceil : DEFAULTS[:height])
      step = interval / (@options[:height].to_f - 1)
      offset = @options[:offset] + AXIS_OFFSET

      width = @series.length + AXIS_OFFSET # one for label and one for axis

      result = Array.new(rows_count) { [BLANK_SPACE] * width }

      rows_count.times.each do |y|
        label = @options[:format] % (max - y * step)
        label_x = [offset - label.length, 0].max
        result[y][label_x] = label
        result[y][label_x + 1] = AXIS_MARK
      end

      (0...@series.length - 1).each do |x|
        _curr = ((max - @series[x + 0]) / step).round
        _next = ((max - @series[x + 1]) / step).round

        if _curr == _next
          result[_curr][x + offset] = colored(HORIZONTAL)
        else
          result[_curr][x + offset] = colored(_curr < _next ? DECREASING_HI : INCREASING_HI)
          result[_next][x + offset] = colored(_curr < _next ? DECREASING_LO : INCREASING_LO)

          ([_curr, _next].min + 1...[_curr, _next].max).each do |y|
            result[y][x + offset] = colored(VERTICAL)
          end
        end
      end

      result
    end

    def plot
      chars.map(&:join).join("\n")
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
