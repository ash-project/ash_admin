defmodule AshAdmin.Themes.AshAdminTheme do
  @moduledoc """
  Custom Cinder theme that matches AshAdmin's existing table styling.

  This theme replicates the visual appearance of the original AshAdmin table
  component to ensure visual consistency when using Cinder for pagination.
  """
  use Cinder.Theme

  # Main table styling - matches the Resource.Table component exactly
  # Table
  # Minimal container - no extra styling
  set :container_class, ""
  # Table wrapper - no styling to match original
  set :table_wrapper_class, ""
  # Main table with exact same classes as original Resource.Table
  set :table_class, "rounded-t-lg m-5 w-5/6 mx-auto text-left"
  # Header styling - minimal to match original with better sort interaction
  set :thead_class, "text-left border-b-2"
  set :header_row_class, ""

  set :th_class,
      "cursor-pointer select-none py-2 pr-2 text-sm font-semibold text-gray-900 transition-colors"

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

  # Pagination styling - minimal to integrate well with table
  # Pagination
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

  # Sorting styling - clean indicators that match AshAdmin's minimal style
  # Sorting
  set :sort_indicator_class, "inline-block ml-1"
  set :sort_arrow_wrapper_class, "text-gray-400 hover:text-gray-600"
  set :sort_asc_icon_class, "h-4 w-4 bg-gray-600 inline-block"
  set :sort_asc_icon_name, "hero-chevron-up"
  set :sort_desc_icon_class, "h-4 w-4 bg-gray-600 inline-block"
  set :sort_desc_icon_name, "hero-chevron-down"
  set :sort_none_icon_class, "h-4 w-4 bg-gray-400 inline-block opacity-50"
  set :sort_none_icon_name, "hero-chevron-up-down"

  # Filter styling - matches AshAdmin's clean, minimal form aesthetic
  # Filters
  # Container styling - minimal border, matches table width
  set :filter_container_class, "border-b-2 border-gray-200 py-4 w-5/6 mx-auto mb-2"
  set :filter_header_class, "flex items-center justify-between mb-4"
  set :filter_title_class, "font-medium text-gray-800"
  set :filter_count_class, "text-sm text-gray-600 bg-gray-200 px-2 py-1 rounded"
  set :filter_clear_all_class, "text-sm text-blue-600 hover:text-blue-800 font-medium underline"
  # Input wrapper and labels - compact layout
  set :filter_inputs_class, "flow-root"
  set :filter_input_wrapper_class, "float-left mr-6 mb-4 space-y-2"
  set :filter_label_class, "block text-sm font-medium text-gray-700"

  set :filter_placeholder_class,
      "text-sm text-gray-500 italic p-3 border border-gray-200 rounded bg-gray-50"

  set :filter_clear_button_class, "ml-2 text-gray-400 hover:text-gray-600 text-sm"
  # Input styling - clean, minimal inputs that match AshAdmin
  set :filter_text_input_class,
      "w-48 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500"

  set :filter_select_input_class,
      "w-48 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500 bg-white"

  set :filter_date_input_class,
      "w-40 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500"

  set :filter_number_input_class,
      "w-28 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500"

  # Select filter (dropdown interface)
  set :filter_select_container_class, "relative"

  set :filter_select_dropdown_class,
      "absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded shadow-lg max-h-48 overflow-auto"

  set :filter_select_option_class,
      "px-3 py-2 hover:bg-gray-100 cursor-pointer flex items-center text-sm"

  set :filter_select_label_class, "text-sm text-gray-800 cursor-pointer select-none flex-1"
  set :filter_select_empty_class, "px-3 py-2 text-sm text-gray-500 italic"
  # Boolean filter styling - compact radio buttons
  set :filter_boolean_container_class, "flex space-x-4 h-10 items-center"
  set :filter_boolean_option_class, "flex items-center space-x-2"
  set :filter_boolean_radio_class, "h-4 w-4 text-blue-600 focus:ring-blue-500 focus:ring-1"
  set :filter_boolean_label_class, "text-sm text-gray-700 cursor-pointer"

  # Loading component styling
  # Loading
  set :loading_overlay_class,
      "absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center"

  set :loading_container_class, "flex flex-col items-center"
  set :loading_class, "mt-2 text-sm text-gray-500"
  set :loading_spinner_class, "animate-spin h-8 w-8 text-indigo-600"
  set :loading_spinner_circle_class, "opacity-25"
  set :loading_spinner_path_class, "opacity-75"
end
