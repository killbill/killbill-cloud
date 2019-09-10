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

      private

      def format_sha(sha)
        return '[???]' if sha.nil?

        "[#{sha[0..5]}..]"
      end
    end

    def format(data, labels = nil)
      puts format_only(data, labels)
    end

    private

    def format_only(data, labels = nil)
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
      labels_format_argument = compute_labels(data, labels)

      border = compute_border(labels)

      format_string = compute_format(labels)

      formatted = "\n#{border}\n"
      formatted += Kernel.format("#{format_string}\n", *labels_format_argument)
      formatted += "#{border}\n"

      data.keys.each do |key|
        v = data[key]

        arguments = []
        labels.inject(arguments) do |res, e|
          formatter = e[:formatter].nil? ? DefaultFormatter.new(e[:label], v[e[:label]]) : e[:formatter].to_class.new(e[:label], v[e[:label]])
          res << formatter.to_s
        end
        formatted += Kernel.format("#{format_string}\n", *arguments)
      end
      formatted += "#{border}\n\n"

      formatted
    end

    def compute_format(labels)
      format = '|'
      labels.inject(format) { |res, lbl| "#{res} %#{lbl[:size]}s |" }
    end

    def compute_border(labels)
      border = '_'
      border = (0...labels.size).inject(border) { |res, _i| "#{res}_" }
      labels.inject(border) do |res, lbl|
        (0...lbl[:size] + 2).each { |_s| res = "#{res}_" }
        res
      end
    end

    # Return labels for each row and update the labels hash with the size of each column
    def compute_labels(data, labels)
      seen_labels = Set.new

      labels_format_argument = []
      data.keys.each do |key|
        v = data[key]
        labels.each do |e|
          # sanitize entry at the same time
          v[e[:label]] = v[e[:label]] || '???'

          # Always recompute the size
          formatter = e[:formatter].nil? ? DefaultFormatter.new(e[:label], v[e[:label]]) : e[:formatter].to_class.new(e[:label], v[e[:label]])
          prev_size = e.key?(:size) ? e[:size] : formatter.label.size
          cur_size = formatter.size
          e[:size] = prev_size < cur_size ? cur_size : prev_size

          # Labels should be unique though
          labels_format_argument << formatter.label unless seen_labels.include?(e[:label])
          seen_labels << e[:label]
        end
      end
      labels_format_argument
    end
  end
end
