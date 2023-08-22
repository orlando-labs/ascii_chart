# frozen_string_literal: true

require 'ascii_chart/version'
require 'ascii_chart/line'

module AsciiChart
  class << self
    def plot(series, **options)
      Line.new(series, options).plot
    end

    def multi_plot(series, **options)
      raise ArgumentError, "Series argument must be an array" unless series.is_a? Array
      raise ArgumentError, "Series argument must be an array of arrays filled with numeric or nil values" unless series.all? { |s| s.all? { |v| v.is_a?(Numeric) || v.nil? } }
      raise ArgumentError, "Series must have the same dimensions: got #{series.map(&:count)}" if series.map(&:count).uniq.size > 1
      
      colors = options[:color]
      raise ArgumentError, "Series colors array must have the same dimension as the series array" if colors.is_a?(Array) && colors.count != series.count

      chars = series.map.with_index do |s, i|
        opts = options.clone
        opts[:color] = colors[i] if colors && colors.is_a?(Array)
        Line.new(s, **opts).chars
      end

      chars.reduce do |a, b|
        a.map.with_index do |row, i|
          row.map.with_index do |sym, j|
            b[i][j] == Line::BLANK_SPACE ? a[i][j] : b[i][j]
          end
        end
      end.map(&:join).join("\n")
    end
  end
end
