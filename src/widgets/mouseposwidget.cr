require "imgui"
require "./crywidget.cr"

module CryPaint
  class MousePosWidget < CryWidget
    def initialize
      @visible = false
    end

    def show
      return if !@visible

      viewport = ImGui.get_main_viewport
      work_pos = viewport.work_pos
      work_size = viewport.work_size
      pad = 10.0
      window_pos = ImVec2.new(0, 0)
      window_pos.x = work_pos.x + work_size.x - pad
      window_pos.y = work_pos.y + work_size.y - pad
      window_pivot = ImVec2.new(1.0, 1.0)
      ImGui.set_next_window_pos(window_pos, ImGuiCond::Always, window_pivot)
      ImGui.window(
        "Mouse position overlay",
        flags: ImGuiWindowFlags::AlwaysAutoResize |
               ImGuiWindowFlags::NoDecoration |
               ImGuiWindowFlags::NoSavedSettings |
               ImGuiWindowFlags::NoFocusOnAppearing |
               ImGuiWindowFlags::NoNav
      ) do
        if ImGui.is_mouse_pos_valid
          pos = ImGui.get_mouse_pos
          ImGui.text("x=#{pos.x}, y=#{pos.y}")
        else
          ImGui.text("x=?, y=?")
        end
      end
    end

    def name_in_menu : String
      "Mouse position"
    end

    def toggle_visibility
      @visible = !@visible
    end

    def visible? : Bool
      @visible
    end
  end
end
