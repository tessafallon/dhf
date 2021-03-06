# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  
  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior
  include Hydra::PolicyAwareAccessControlsEnforcement
  
	# This applies appropriate access controls to all solr queries
  self.solr_search_params_logic += [:add_access_controls_to_solr_params_if_not_admin]
  
  # This filters out objects that you want to exclude from search results, like FileAssets
  self.solr_search_params_logic += [:only_wanted_models]
  self.solr_search_params_logic += [:only_published_items]
  self.solr_search_params_logic += [:limit_to_non_hidden_items]

  configure_blacklight do |config|
    config.default_solr_params = { 
      :qt => 'search',
      :rows => 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'

    # solr field configuration for document/show views
    config.show.title_field = 'title_tesim'
    config.show.display_type_field = 'has_model_ssim'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field 'format_sim', :label => 'Format', :limit => 5, :expanded => true
    # Eventually these need to be merged into a single facet
    config.add_facet_field 'creator_sim', :label => 'Main contributor', :limit => 5
    #TODO add "Date" facet that points to issue date in mediaobject
    config.add_facet_field 'date_sim', :label => 'Date', :limit => 5
    config.add_facet_field 'genre_sim', :label => 'Genres', :limit => 5
    config.add_facet_field 'collection_ssim', :label => 'Collection', :limit => 5
    config.add_facet_field 'unit_ssim', :label => 'Unit', :limit => 5


    # Hide these facets if not a Collection Manager
    config.add_facet_field 'workflow_published_sim', :label => 'Published', :limit => 5, :if_user_can => [:create, MediaObject], :group=>"workflow"
    config.add_facet_field 'created_by_sim', :label => 'Created by', :limit => 5, :if_user_can => [:create, MediaObject], :group=>"workflow"
    config.add_facet_field 'read_access_virtual_group_ssim', :label => 'Class', :limit => 5, :if_user_can => [:create, MediaObject], :group=>"workflow", :helper_method => :vgroup_display

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys    


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'creator_ssim', :label => 'Main contributors:', :helper_method => :contributor_index_display 
    config.add_index_field 'date_ssi', :label => 'Date:' 
    config.add_index_field 'summary_ssim', label: 'Summary:', :helper_method => :description_index_display

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'title_sim', :label => 'Title' 
    config.add_show_field 'format_sim', :label => 'Format' 
    config.add_show_field 'creator_sim', :label => 'Creator' 
    config.add_show_field 'language_sim', :label => 'Language'
    config.add_show_field 'date_sim', label: 'Date'
    config.add_show_field 'abstract_sim', label: 'Abstract'
    config.add_show_field 'location_sim', label: 'Locations'
    config.add_show_field 'time_period_sim', label: 'Time periods'
    config.add_show_field 'contributor_sim', label: 'Contributors'
    config.add_show_field 'publisher_sim', label: 'Publisher'
    config.add_show_field 'genre_sim', label: 'Genre'
    config.add_show_field 'publication_location_sim', label: 'Place of publication'
    config.add_show_field 'terms_sim', label: 'Terms'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    config.add_search_field 'all_fields', :label => 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
    
    config.add_search_field('creator') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'creator' }
      field.solr_local_parameters = { 
        :qf => '$creator_qf',
        :pf => '$creator_pf'
      }
    end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = { 
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_ssi asc, date_ssi desc', :label => 'Relevance'
    config.add_sort_field 'date_ssi desc, title_ssi asc', :label => 'Year'
    config.add_sort_field 'creator_ssi asc, title_ssi asc', :label => 'Main contributor'
    config.add_sort_field 'title_ssi asc, date_ssi desc', :label => 'Title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def only_wanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"info:fedora/afmodel:MediaObject"'
  end

  def only_published_items(solr_parameters, user_parameters)
    if cannot? :create, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'workflow_published_sim:"Published"'
    end
  end

  def limit_to_non_hidden_items(solr_parameters, user_parameters)
    if cannot? :create, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << '!hidden_bsi:true'
    end
  end

	def add_access_controls_to_solr_params_if_not_admin(solr_parameters, user_parameters)
		if cannot? :discover_everything, MediaObject
			add_access_controls_to_solr_params(solr_parameters, user_parameters)
		end
	end
end 
