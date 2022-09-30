require "imgui"
require "./crywidget.cr"
require "../colors.cr"

module CryPaint
  class ColorsWidget < CryWidget
    @palette : Array(ImVec4)
    @colors : CryPaint::Colors

    def initialize(colors : CryPaint::Colors)
      @visible = true
      @colors = colors
      @palette = (0...36).map do |i|
        ImGui.hsv(i / 36_f32, 0.8_f32, 0.8_f32)
      end
    end

    def show
      return if !@visible

      ImGui.window("Colors", flags: ImGuiWindowFlags::AlwaysAutoResize) do
        ImGui.separator
        ImGui.color_picker4(
          "##picker",
          pointerof(@colors.primary),
          ImGuiColorEditFlags::NoSidePreview |
          ImGuiColorEditFlags::NoSmallPreview |
          ImGuiColorEditFlags::AlphaBar
        )
        ImGui.same_line
        ImGui.group do
          preview_size = ImVec2.new(80, 30)
          preview_flags = ImGuiColorEditFlags::NoPicker |
                          ImGuiColorEditFlags::AlphaPreviewHalf

          if ImGui.color_button("##primary", @colors.primary, preview_flags, preview_size)
            @colors.set_primary(@colors.primary) # refreshes @colors.backup
          end
          ImGui.drag_drop_target do
            if payload = ImGui.accept_drag_drop_payload(ImGui::PAYLOAD_TYPE_COLOR_4F)
              data = payload.data.as(Float32*)
              @colors.set_primary(ImGui.rgb(data[0], data[1], data[2], data[3]))
            end
          end

          ImGui.same_line

          if ImGui.color_button("##secondary", @colors.secondary, preview_flags, preview_size)
            @colors.set_primary(@colors.secondary)
          end
          ImGui.drag_drop_target do
            if payload = ImGui.accept_drag_drop_payload(ImGui::PAYLOAD_TYPE_COLOR_4F)
              data = payload.data.as(Float32*)
              @colors.set_secondary(ImGui.rgb(data[0], data[1], data[2], data[3]))
            end
          end

          if ImGui.color_button("##previous", @colors.backup, preview_flags, preview_size)
            @colors.set_primary(@colors.backup)
          end

          ImGui.separator

          ImGui.text("Palette")
          palette_flags = ImGuiColorEditFlags::NoPicker |
                          ImGuiColorEditFlags::NoTooltip
          button_size = ImVec2.new(20, 20)

          @palette.each_index do |i|
            ImGui.same_line if i % 6 > 0
            color = @palette[i]
            if ImGui.color_button("##palette#{i}", @palette[i], palette_flags, button_size)
              @colors.set_primary(color)
            end
            ImGui.drag_drop_target do
              if payload = ImGui.accept_drag_drop_payload(ImGui::PAYLOAD_TYPE_COLOR_4F)
                data = payload.data.as(Float32*)
                @palette[i] = ImGui.rgb(data[0], data[1], data[2], 1.0_f32)
              end
            end
          end
        end
      end
    end

    def name_in_menu : String
      "Colors"
    end

    def toggle_visibility
      @visible = !@visible
    end

    def visible? : Bool
      @visible
    end
  end
end
