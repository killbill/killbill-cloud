# frozen_string_literal: true

module KPM
  class Coordinates
    class << self
      def build_coordinates(coordinate_map)
        group_id = coordinate_map[:group_id]
        artifact_id = coordinate_map[:artifact_id]
        packaging = coordinate_map[:packaging]
        classifier = coordinate_map[:classifier]
        version = coordinate_map[:version]

        if classifier.nil?
          if version.nil?
            "#{group_id}:#{artifact_id}:#{packaging}"
          else
            "#{group_id}:#{artifact_id}:#{packaging}:#{version}"
          end
        else
          "#{group_id}:#{artifact_id}:#{packaging}:#{classifier}:#{version}"
        end
      end

      def get_coordinate_map(entry)
        parts = entry.split(':')
        length = parts.size
        if length == 3
          { group_id: parts[0], artifact_id: parts[1], packaging: parts[2] }
        elsif length == 4
          { group_id: parts[0], artifact_id: parts[1], packaging: parts[2], version: parts[3] }
        elsif length == 5
          { group_id: parts[0], artifact_id: parts[1], packaging: parts[2], classifier: parts[3], version: parts[4] }
        end
      end
    end
  end
end
