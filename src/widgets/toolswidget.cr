require "imgui"
require "./crywidget.cr"

module CryPaint
  class ToolsWidget < CryWidget
    def initialize(draw_radius_ptr : Pointer(Int32))
      @visible = true
      @draw_radius_ptr = draw_radius_ptr
    end

    def show
      return if !@visible

      ImGui.window("Tool settings") do
        ImGui.drag_int("Radius", @draw_radius_ptr, v_min: 1, v_max: 9001)
      end
    end

    def name_in_menu : String
      "Tool settings"
    end

    def toggle_visibility
      @visible = !@visible
    end

    def visible? : Bool
      @visible
    end
  end
end
