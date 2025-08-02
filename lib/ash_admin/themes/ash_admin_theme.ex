defmodule AshAdmin.Themes.AshAdminTheme do
  @moduledoc """
  Custom Cinder theme that matches AshAdmin's existing table styling.

  This theme replicates the visual appearance of the original AshAdmin table
  component to ensure visual consistency when using Cinder for pagination.
  """
  use Cinder.Theme

  # Main table styling - matches the Resource.Table component exactly
  component Cinder.Components.Table do
    # Minimal container - no extra styling
    set :container_class, ""

    # Table wrapper - no styling to match original
    set :table_wrapper_class, ""

    # Main table with exact same classes as original Resource.Table
    set :table_class, "rounded-t-lg m-5 w-5/6 mx-auto text-left"

    # Header styling - minimal to match original
    set :thead_class, "text-left border-b-2"
    set :header_row_class, ""
    set :th_class, ""

    # Body styling - no extra classes
    set :tbody_class, ""

    # Row styling - exact border from original
    set :row_class, "border-b-2"

    # Cell styling - only padding from original
    set :td_class, "py-3"

    # Simple loading and error states
    set :loading_class, "text-center py-4 text-gray-500"
    set :empty_class, "text-center py-4 text-gray-500"
    set :error_container_class, "text-center py-4"
    set :error_message_class, "text-red-600"
  end

  # Pagination styling - minimal to integrate well with table
  component Cinder.Components.Pagination do
    set :pagination_wrapper_class, "w-5/6 mx-auto"

    set :pagination_container_class,
        "bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200"

    # Simple info styling
    set :pagination_info_class, "text-sm text-gray-700"
    set :pagination_count_class, "font-medium text-gray-900"

    # Clean navigation styling
    set :pagination_nav_class, "inline-flex rounded-md shadow-sm -space-x-px"

    set :pagination_button_class,
        "relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"

    set :pagination_current_class,
        "bg-indigo-50 border-indigo-500 text-indigo-600 relative inline-flex items-center px-4 py-2 border text-sm font-medium"
  end

  # Sorting styling - simple indicators
  component Cinder.Components.Sorting do
    set :sort_indicator_class, "ml-1"
    set :sort_arrow_wrapper_class, "text-gray-400"
    set :sort_asc_icon_class, "h-4 w-4"
    set :sort_asc_icon_name, "hero-chevron-up"
    set :sort_desc_icon_class, "h-4 w-4"
    set :sort_desc_icon_name, "hero-chevron-down"
    set :sort_none_icon_class, "h-4 w-4"
    set :sort_none_icon_name, "hero-chevron-up-down"
  end

  # Filter styling - matches AshAdmin's form aesthetic
  component Cinder.Components.Filters do
    # Container styling - clean and simple
    set :filter_container_class, "bg-white border border-gray-200 rounded-md p-4 mb-4"
    set :filter_header_class, "mb-4"
    set :filter_title_class, "text-lg font-medium text-gray-900 mb-2"
    set :filter_count_class, "text-sm text-gray-500"
    set :filter_clear_all_class, "text-sm text-indigo-600 hover:text-indigo-500 font-medium"

    # Input wrapper and labels
    set :filter_inputs_class, "grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
    set :filter_input_wrapper_class, ""
    set :filter_label_class, "block text-sm font-medium text-gray-700 mb-1"
    set :filter_clear_button_class, "ml-2 text-gray-400 hover:text-gray-600"

    # Input styling - matches AshAdmin form inputs
    set :filter_text_input_class,
        "block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"

    set :filter_select_input_class,
        "block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"

    set :filter_date_input_class,
        "block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"

    set :filter_number_input_class,
        "block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"

    # Boolean filter styling
    set :filter_boolean_container_class, "flex space-x-4"
    set :filter_boolean_option_class, "flex items-center"

    set :filter_boolean_radio_class,
        "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"

    set :filter_boolean_label_class, "ml-2 block text-sm text-gray-900"

    # Multi-select dropdown styling
    set :filter_multiselect_container_class, "relative"

    set :filter_multiselect_dropdown_class,
        "absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto"

    set :filter_multiselect_option_class,
        "px-3 py-2 hover:bg-gray-100 cursor-pointer flex items-center"

    set :filter_multiselect_checkbox_class,
        "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded mr-2"

    set :filter_multiselect_label_class, "text-sm text-gray-900"
    set :filter_multiselect_empty_class, "px-3 py-2 text-sm text-gray-500 italic"

    # Multi-checkboxes styling
    set :filter_multicheckboxes_container_class, "space-y-2 max-h-40 overflow-y-auto"
    set :filter_multicheckboxes_option_class, "flex items-center"

    set :filter_multicheckboxes_checkbox_class,
        "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"

    set :filter_multicheckboxes_label_class, "ml-2 text-sm text-gray-900"

    # Range filter styling
    set :filter_range_container_class, "flex items-center space-x-2"
    set :filter_range_input_group_class, "flex items-center space-x-2"
    set :filter_range_separator_class, "text-gray-500"
  end

  # Loading component styling
  component Cinder.Components.Loading do
    set :loading_overlay_class,
        "absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center"

    set :loading_container_class, "flex flex-col items-center"
    set :loading_class, "mt-2 text-sm text-gray-500"
    set :loading_spinner_class, "animate-spin h-8 w-8 text-indigo-600"
    set :loading_spinner_circle_class, "opacity-25"
    set :loading_spinner_path_class, "opacity-75"
  end
end
