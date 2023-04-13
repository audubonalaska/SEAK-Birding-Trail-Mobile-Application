import QtQuick 2.9

Item {
    // Popup
    readonly property string photos:qsTr("Photos")
    readonly property string files:qsTr("Files")
    readonly property string next:qsTr("Next")
    readonly property string no_permission_to_edit: qsTr("You don't have the permission to edit feature attributes.")
    readonly property string save_changes:qsTr("Save changes?")
    readonly property string failed_to_save_changes:qsTr("Failed to save changes. Retry?")
    readonly property string delete_this_attachment:qsTr("Are you sure you want to delete this attachment?")
    readonly property string failed_to_upload_attachment:qsTr("Failed to upload attachment. Retry?")
    readonly property string cannot_edit_attachment:qsTr("Cannot edit attachments")
    readonly property string hours_ago:qsTr("%1 hours ago")
    readonly property string minutes_ago:qsTr("%1 minutes ago")
    readonly property string seconds_ago:qsTr("%1 seconds ago")
    readonly property string hour_ago:qsTr("%1 hour ago")
    readonly property string minute_ago:qsTr("%1 minute ago")
    readonly property string second_ago:qsTr("%1 second ago")
    readonly property string edited:qsTr("Last Edited")
    readonly property string hrs: qsTr("hrs")

    //textfield
    readonly property string enter_number:qsTr("Enter a number")
    readonly property string enter_number_x_y:qsTr("Enter a number between %1 and %2")
    readonly property string enter_choice:qsTr("Enter a number between %1 and %2 or select from below choices.")
    readonly property string enter_text: qsTr("Enter some text")
    readonly property string required_field:qsTr("Required field")
    readonly property string no_value: qsTr("No Value")
    //Progress:
    readonly property string saving:qsTr("Saving…")
    readonly property string uploading:qsTr("Uploading…")

    //Toast message:
    readonly property string successfully_saved:qsTr("Successfully saved.")
    readonly property string successfully_deleted:qsTr("Successfully deleted.")
    readonly property string successfully_uploaded: qsTr("Successfully uploaded attachment.")
    readonly property string large_file_uploaded: qsTr("Large file can take longer to appear.")
    readonly property string timedout_fetching_attachments:qsTr("Timed out while fetching Attachments. Please try again.")



    //Buttons:
    readonly property string save:qsTr("Save")
    readonly property string cancel:qsTr("Cancel")
    readonly property string add_attachment:qsTr("Add attachment")
    readonly property string upload: qsTr("Upload")

    //units
    readonly property string km:qsTr("km")
    readonly property string mi:qsTr("mi")
    readonly property string m:qsTr("m")
    readonly property string ft:qsTr("ft")
    readonly property string yd:qsTr("yd")
    readonly property string sqft:qsTr("sq ft")
    readonly property string sqkm:qsTr("sq km")
    readonly property string sqmi:qsTr("sq mi")
    readonly property string sqm:qsTr("sq m")

    readonly property string kb: qsTr("KB")
    readonly property string mb: qsTr("MB")
    readonly property string gb: qsTr("GB")

    //SpatialSearch
    readonly property string filters:qsTr("Filters")
    readonly property string reset:qsTr("Reset")
    readonly property string update:qsTr("Update")
    readonly property string see_results:qsTr("See Results")
    readonly property string search_criteria:qsTr("Search criteria")
    readonly property string distance:qsTr("Distance")
    readonly property string map_extent:qsTr("Map Extent")
    readonly property string shape:qsTr("Shape")
    readonly property string search_distance_hint:qsTr("Set a distance and unit, then tap on the map to search within the radius.")
    readonly property string search_extent_hint:qsTr("Position the map to define a search extent, and then tap the Search this area button.")
    readonly property string search_results_within:qsTr("Search results within")
    readonly property string select_category:qsTr("Select category (optional)")
    readonly property string show_layer_list:qsTr("Only visible layers are shown. Zoom in or out to see hidden layers.")
    readonly property string no_results_found:qsTr("No results found.")
    readonly property string search_this_area:qsTr("Search this area")
    readonly property string spatialsearch_distance_tooltip:qsTr("Tap on the map to search by distance.")
    readonly property string unsupported_layers:qsTr("No layers found which support query operation.")
    readonly property string clear_search_results:qsTr("Clear results")

    readonly property string no_basemaps_found:qsTr("No BaseMaps found in the configured basemap group.")

    //Locator
    readonly property string locator_not_licensed:qsTr("ArcGIS runtime is not licensed to use the Street Map Extension")
    readonly property string locator_not_supported:qsTr("Locators created with the Create Address Locator tool are not supported")
    readonly property string locator_loading_error:qsTr("Error in loading locator")

    //profile
    readonly property string distance_mi:qsTr("Distance (%1)").arg(strings.mi)
    readonly property string distance_km:qsTr("Distance (%1)").arg(strings.km)
    readonly property string elevation_units:qsTr("Elevation (%L1)")
    readonly property string elevation_request_network_error:qsTr("Elevation request network error %L1.")
    readonly property string elevation_request_http_error: qsTr("Elevation request HTTP error %L1.")
    readonly property string elevation_request_json_error:qsTr("Elevation request JSON error.")
    readonly property string fetchdata_error:qsTr("Unable to fetch data from the elevation service.")
    readonly property string elevation_summary_request_network_error:qsTr("Elevation request network error %L1.")
    readonly property string elevation_summary_request_http_error: qsTr("Elevation request HTTP error %L1.")
    readonly property string elevation_summary_request_json_error :qsTr("Elevation summary service request JSON error.")
    readonly property string max_slope:qsTr("Max Slope")
    readonly property string min_slope:qsTr("Min Slope")
    readonly property string avg_slope:qsTr("Avg Slope")
    readonly property string max_elevation:qsTr("Max")
    readonly property string min_elevation:qsTr("Min")
    readonly property string gain:qsTr("Gain")
    readonly property string loss:qsTr("Loss")
    readonly property string trail_length:qsTr("Length")
    readonly property string metric:qsTr("Metric")
    readonly property string imperial:qsTr("Imperial")
    readonly property string loading: qsTr("Loading...")

    // GraticulesView
    readonly property string none: qsTr("None")
    readonly property string grid: qsTr("Grid")

    // BasemapsView - open for extension (can add future basemaps to support translation)
    readonly property string basemapUSATopoMaps: qsTr("USA Topo Maps")

    readonly property string basemapImagery: qsTr("Imagery")
    readonly property string basemapImageryHybrid: qsTr("Imagery Hybrid")
    readonly property string basemapImageryWGS84: qsTr("Imagery (WGS84)")
    readonly property string basemapImageryHybridWGS84: qsTr("Imagery Hybrid (WGS84)")

    readonly property string basemapUSGSNationalMap: qsTr("USGS National Map")

    readonly property string basemapNationalGeographic: qsTr("National Geographic")

    readonly property string basemapOceans: qsTr("Oceans")

    // OSM => OpenStreetMap
    readonly property string basemapOSM: qsTr("OpenStreetMap")
    readonly property string basemapOSMVector: qsTr("OpenStreetMap Vector Basemap")
    readonly property string basemapOSMVectorWGS84: qsTr("OpenStreetMap Vector Basemap (WGS84)")

    readonly property string basemapTopographic: qsTr("Topographic")
    readonly property string basemapTopographicWGS84: qsTr("Topographic (WGS84)")

    readonly property string basemapStreets: qsTr("Streets")
    readonly property string basemapStreetsNight: qsTr("Streets (Night)")
    readonly property string basemapStreetsWithRelief: qsTr("Streets (with Relief)")

    readonly property string basemapImageryWithLabels: qsTr("Imagery with Labels")
    readonly property string basemapTerrainWithLabels: qsTr("Terrain with Labels")

    readonly property string basemapDarkGrayCanvas: qsTr("Dark Gray Canvas")
    readonly property string basemapLightGrayCanvas: qsTr("Light Gray Canvas")
    readonly property string basemapLightGrayCanvasWGS84: qsTr("Light Gray Canvas (WGS84)")

    readonly property string basemapNovamap: qsTr("Nova Map")
    readonly property string basemapNovamapWGS84: qsTr("Nova Map (WGS84)")

    readonly property string basemapMidCenturyMap: qsTr("Mid-Century Map")
    readonly property string basemapMidCenturyMapWGS84: qsTr("Mid-Century Map (WGS84)")

    readonly property string basemapNavigation: qsTr("Navigation")
    readonly property string basemapNavigationDarkMode: qsTr("Navigation (Dark Mode)")
    readonly property string basemapNavigationWGS84: qsTr("Navigation (WGS84)")

    readonly property string basemapCommunityMap: qsTr("Community Map")

    readonly property string basemapHumanGeographyMap: qsTr("Human Geography Map")


    //edit
    readonly property string kSelectType: qsTr("Select a type")


    readonly property string edit_attribute:qsTr("Edit Attribute")
    readonly property string edit_geometry:qsTr("Edit Geometry")
    readonly property string delete_feature:qsTr("Delete")
    readonly property string delete_this_feature:qsTr("Are you sure you want to delete this feature?")
    readonly property string cancel_editing:qsTr("Are you sure you want to cancel editing?")
    readonly property string reset_editing:qsTr("Are you sure you want to discard edits?")
    readonly property string discard_edits:qsTr("Discard Edits")
    readonly property string invalid_geometry:qsTr("Invalid geometry %1")
    readonly property string discard:qsTr("Discard")
    readonly property string apply:qsTr("Apply")
    readonly property string kCreateNewFeature: qsTr("Add Details")
    readonly property string create:qsTr("Create")
    readonly property string no_editable_layers:qsTr("Map does not contain any editable layers.")
    readonly property string kSearch: qsTr("Search")
    readonly property string creating_feature:qsTr("Creating feature...")
    readonly property string no_attachments: qsTr("No attachments.")
    readonly property string kMapArea: qsTr("Offline Maps")
    readonly property string done:qsTr("DONE")
    readonly property string invalid_combination_warning:qsTr("One of the following values may cause an invalid combination with other fields")
    readonly property string show_invalid_constraints:qsTr("Choosing the following values may result in an invalid combination with other fields")
    readonly property string incompatible_fields:qsTr("Invalid value combination")
    readonly property string no_edits_to_save:qsTr("There are no edits to save")
    readonly property string error_while_saving:qsTr("Error while Saving:%1")
    readonly property string sketch_not_valid:qsTr("Sketch is not valid")
    readonly property string recommended_text:qsTr("RECOMMENDED")
    readonly property string others_text:qsTr("OTHERS")
    readonly property string invalid_fields:qsTr("Invalid Fields")
    readonly property string show_null_fields:qsTr("%1 cannot be null")

    readonly property string failed_to_delete :qsTr("Failed to delete")

    readonly property string error_in_saving:qsTr("Error in saving")
    readonly property string no_updates_available:qsTr("There are no updates available at this time.")
    readonly property string download_failed:qsTr("Download Failed")
    readonly property string offline_sync_completed:qsTr("Offline map area syncing completed.")
    readonly property string offline_failed_to_download:qsTr("Offline map area failed to download.")
    readonly property string unknown_error:qsTr("Unknown Error")
    readonly property string remove_offline_area:qsTr("Remove offline area")
    readonly property string remove_offline_area_warning:qsTr("This will remove the downloaded offline map area %1 from the device. Would you like to continue?")
    readonly property string no_offline_area_available:qsTr("There are no offline map areas.")
    readonly property string remove:qsTr("Remove")
    readonly property string open:qsTr("Open")

    readonly property string kMeters: qsTr("%L1 m")
    readonly property string kMiles: qsTr("%L1 mi")
    readonly property string kKilometers: qsTr("%L1 km")
    readonly property string kFeet: qsTr("%L1 ft")
    readonly property string kYards: qsTr("%L1 yd")

    readonly property string kSqMeters: qsTr("%L1 sq m")
    readonly property string kSqMiles: qsTr("%L1 sq mi")
    readonly property string kSqKilometers: qsTr("%L1 sq km")
    readonly property string kSqYards: qsTr("%L1 sq yd")
    readonly property string kSqFeet: qsTr("%L1 sq ft")

    readonly property string kDistance: qsTr("Distance")
    readonly property string kArea: qsTr("Area")

    readonly property string page_counter:qsTr("%L1 of %L2")
    readonly property string no_attributes_configured:qsTr("There are no attributes configured.")
    readonly property string no_media:qsTr("There are no media.")
    readonly property string items:qsTr("Items:")
    readonly property string no_legend:qsTr("There are no legends to show.")

     // floor-aware
    readonly property string pan_to_browse_facilities: qsTr("Pan the map to browse Facilities")
    readonly property string select_site: qsTr("Select Site")

}
