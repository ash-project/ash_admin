# SPDX-FileCopyrightText: 2020 Zach Daniel
# SPDX-FileCopyrightText: 2020 ash_admin contributors <https://github.com/ash-project/ash_admin/graphs/contributors>
#
# SPDX-License-Identifier: MIT

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
  set :table_wrapper_class, "p-6 pb-0"
  # Main table with exact same classes as original Resource.Table
  set :table_class, "rounded-t-lg my-5 px-6 w-full text-left"
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

  # Pagination styling
  # Pagination
  set :pagination_wrapper_class, "px-6 pb-6"

  set :pagination_container_class,
      "py-3 flex items-center justify-between"

  # Simple info styling
  set :pagination_info_class, "text-sm text-gray-500"
  set :pagination_count_class, "font-medium text-gray-700"
  # Clean navigation styling
  set :pagination_nav_class, "inline-flex -space-x-px rounded-md overflow-hidden"

  set :pagination_button_class,
      "relative inline-flex items-center px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-100 border border-gray-200"

  set :pagination_current_class,
      "relative inline-flex items-center px-3 py-1.5 text-sm font-medium bg-indigo-600 text-white border border-indigo-600"

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

  # Filter styling
  # Filters
  set :filter_container_class, "px-6 py-2"
  set :filter_header_class, "hidden"
  set :filter_title_class, "hidden"
  set :filter_count_class, "hidden"
  set :filter_clear_all_class, "text-sm text-indigo-600 hover:text-indigo-800 font-medium"
  # Input wrapper and labels
  set :filter_inputs_class, "flex flex-wrap gap-x-6 gap-y-4 items-end"
  set :filter_input_wrapper_class, "flex-none space-y-1"
  set :filter_label_class, "block text-sm font-medium text-gray-700"

  set :filter_placeholder_class,
      "text-sm text-gray-400 italic px-3 py-2 border border-gray-200 rounded"

  set :filter_clear_button_class, "ml-2 text-gray-400 hover:text-gray-600 text-sm"
  # Input styling - larger inputs with thicker borders to match table
  set :filter_text_input_class,
      "w-48 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"

  set :filter_select_input_class,
      "w-48 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 bg-white"

  set :filter_date_input_class,
      "px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"

  set :filter_number_input_class,
      "w-28 px-3 py-2 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"

  # Range filter styling - inline layout for date/number ranges
  set :filter_range_container_class, "flex items-center gap-2"
  set :filter_range_input_group_class, ""
  set :filter_range_separator_class, "text-xs text-gray-400"
  # Select filter (dropdown interface)
  set :filter_select_container_class, "relative"

  set :filter_select_dropdown_class,
      "absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded shadow-lg max-h-48 overflow-auto"

  set :filter_select_option_class,
      "px-3 py-1.5 hover:bg-gray-100 cursor-pointer flex items-center text-sm"

  set :filter_select_label_class, "text-sm text-gray-700 cursor-pointer select-none flex-1"
  set :filter_select_empty_class, "px-3 py-1.5 text-sm text-gray-500 italic"
  set :filter_select_placeholder_class, "text-gray-400"
  set :filter_select_arrow_class, "h-4 w-4 text-gray-400"
  # Boolean filter styling - compact radio buttons
  set :filter_radio_group_container_class, "flex space-x-3 h-8 items-center"
  set :filter_radio_group_option_class, "flex items-center space-x-1.5"

  set :filter_radio_group_radio_class,
      "h-3.5 w-3.5 text-indigo-600 focus:ring-indigo-500 focus:ring-1"

  set :filter_radio_group_label_class, "text-sm text-gray-600 cursor-pointer"

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
