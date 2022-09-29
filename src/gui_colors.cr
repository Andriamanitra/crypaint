module GUI_Colors

  @palette : Array(ImGui::ImVec4)
  @palette = (0...36).map { |i|
    ImGui.hsv(i / 36_f32, 0.8_f32, 0.8_f32)
  }

  def show_colors_window
    ImGui.window("Colors", flags: ImGui::ImGuiWindowFlags::AlwaysAutoResize) do
      ImGui.separator
      ImGui.color_picker4(
        "##picker",
        pointerof(@color),
        ImGui::ImGuiColorEditFlags::NoSidePreview |
        ImGui::ImGuiColorEditFlags::NoSmallPreview |
        ImGui::ImGuiColorEditFlags::AlphaBar
      )
      ImGui.same_line
      ImGui.group do
        preview_size = ImGui::ImVec2.new(80, 30)
        preview_flags = ImGui::ImGuiColorEditFlags::NoPicker |
                        ImGui::ImGuiColorEditFlags::AlphaPreviewHalf
        if ImGui.color_button("##current", @color, preview_flags, preview_size)
          set_current_color(@color)
        end
        if ImGui.color_button("##previous", @bkup_color, preview_flags, preview_size)
          set_current_color(@bkup_color)
        end
        ImGui.separator
        ImGui.text("Palette")
        palette_flags = ImGui::ImGuiColorEditFlags::NoPicker |
                        ImGui::ImGuiColorEditFlags::NoTooltip
        button_size = ImGui::ImVec2.new(20, 20)

        @palette.each_index do |i|
          ImGui.same_line if i % 6 > 0
          color = @palette[i]
          if ImGui.color_button("##palette#{i}", @palette[i], palette_flags, button_size)
            set_current_color(ImGui::ImVec4.new(color.x, color.y, color.z, @color.w))
          end
          ImGui.drag_drop_target do
            if payload = ImGui.accept_drag_drop_payload(ImGui::PAYLOAD_TYPE_COLOR_4F)
              data = payload.data.as(Float32*)
              @palette[i] = ImGui.rgb(data[0], data[1], data[2])
            end
          end
        end
      end
    end
  end

end
