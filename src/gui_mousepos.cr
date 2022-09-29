module GUI_MousePos

  def show_mousepos_window
    viewport = ImGui.get_main_viewport
    work_pos = viewport.work_pos
    work_size = viewport.work_size
    pad = 10.0
    window_pos = ImGui::ImVec2.new(0, 0)
    window_pos.x = work_pos.x + work_size.x - pad
    window_pos.y = work_pos.y + work_size.y - pad
    window_pivot = ImGui::ImVec2.new(1.0, 1.0)
    ImGui.set_next_window_pos(window_pos, ImGui::ImGuiCond::Always, window_pivot)
    ImGui.window(
      "Mouse position overlay",
      flags: ImGui::ImGuiWindowFlags::AlwaysAutoResize |
             ImGui::ImGuiWindowFlags::NoDecoration |
             ImGui::ImGuiWindowFlags::NoSavedSettings |
             ImGui::ImGuiWindowFlags::NoFocusOnAppearing |
             ImGui::ImGuiWindowFlags::NoNav
    ) do
      if ImGui.is_mouse_pos_valid
        pos = ImGui.get_mouse_pos
        ImGui.text("x=#{pos.x}, y=#{pos.y}")
      else
        ImGui.text("x=?, y=?")
      end
    end
  end

end
