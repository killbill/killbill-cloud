# frozen_string_literal: true

# Extend String to be able to instantiate a object based on its classname
class String
  def to_class
    split('::').inject(Kernel) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
end

module KPM
  class Formatter
    def initialize; end

    # Used for normal types where to_s is enough
    class DefaultFormatter
      def initialize(label, input)
        @label = label
        @input = input
      end

      def size
        to_s.size
      end

      def to_s
        @input.to_s
      end

      def label
        @label.to_s.upcase.gsub(/_/, ' ')
      end
    end

    # Used for the version map
    class VersionFormatter
      def initialize(label, versions)
        @label = label
        @versions = versions
      end

      def size
        to_s.size
      end

      def to_s
        @versions.map do |q|
          sha1 = format_sha(q[:sha1])
          disabled = ''
          disabled = '(x)' if q[:is_disabled]
          default = ''
          default = '(*)' if q[:is_default]
          "#{q[:version]}#{sha1}#{default}#{disabled}"
        end.join(', ')
      end

      def label
        "#{@label.to_s.upcase.gsub(/_/, ' ')} sha1=[], def=(*), del=(x)"
      end

      def format_sha(sha)
        return '[???]' if sha.nil?

        "[#{sha[0..5]}..]"
      end
    end

    def format(data, labels = nil)
      return if data.nil? || data.empty?

      if labels.nil?

        # What we want to output
        labels = [{ label: :plugin_name },
                  { label: :plugin_key },
                  { label: :type },
                  { label: :group_id },
                  { label: :artifact_id },
                  { label: :packaging },
                  { label: :versions, formatter: VersionFormatter.name }]
      end

      # Compute label to print along with max size for each label
      labels_format_argument = []
      data.keys.each do |key|
        v = data[key]
        labels.each do |e|
          # sanitize entry at the same time
          v[e[:label]] = v[e[:label]] || '???'

          formatter = e[:formatter].nil? ? DefaultFormatter.new(e[:label], v[e[:label]]) : e[:formatter].to_class.new(e[:label], v[e[:label]])
          prev_size = e.key?(:size) ? e[:size] : formatter.label.size
          cur_size = formatter.size
          e[:size] = prev_size < cur_size ? cur_size : prev_size
          labels_format_argument << formatter.label
        end
      end

      border = '_'
      border = (0...labels.size).inject(border) { |res, _i| "#{res}_" }
      border = labels.inject(border) do |res, lbl|
        (0...lbl[:size] + 2).each { |_s| res = "#{res}_" }
        res
      end
      format = '|'
      format = labels.inject(format) { |res, lbl| "#{res} %#{lbl[:size]}s |" }

      puts "\n#{border}\n"
      puts format("#{format}\n", labels_format_argument)
      puts "#{border}\n"

      data.keys.each do |key|
        v = data[key]

        arguments = []
        labels.inject(arguments) do |res, e|
          formatter = e[:formatter].nil? ? DefaultFormatter.new(e[:label], v[e[:label]]) : e[:formatter].to_class.new(e[:label], v[e[:label]])
          res << formatter.to_s
        end
        puts format("#{format}\n", arguments)
      end
      puts "#{border}\n\n"
    end
  end
end
