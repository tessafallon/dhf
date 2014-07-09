module Hydra
  module Datastream
      class RightsMetadata < ActiveFedora::NokogiriDatastream
        extend_terminology do |t|
          t.root(:path=>"rightsMetadata", :xmlns=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1", :schema=>"http://github.com/projecthydra/schemas/tree/v1/rightsMetadata.xsd")
          t.exceptions_access(:ref=>[:access], :attributes=>{:type=>"exceptions"})
        end

        # @param [Symbol] type (either :group or :person)
        # @return 
        # This method limits the response to known access levels.  Probably runs a bit faster than .permissions().
        def quick_search_by_type(type)
          result = {}
          [{:discover_access=>"discover"},{:read_access=>"read"},{:edit_access=>"edit"},{:exceptions_access=>"exceptions"}].each do |access_levels_hash|
            access_level = access_levels_hash.keys.first
            access_level_name = access_levels_hash.values.first
            self.find_by_terms(*[access_level, type]).each do |entry|
              result[entry.text] = access_level_name
            end
          end
        return result
        end
      end
  end
end
