require "imgui"

module CryPaint
  class Colors
    getter primary : ImGui::ImVec4
    getter secondary : ImGui::ImVec4
    getter backup : ImGui::ImVec4

    def initialize
      @primary = ImGui.color(255, 0, 255)
      @secondary = ImGui.color(0, 123, 123)

      # Used to show the previously active color in color picker
      @backup = @primary
    end

    # used by color picker to NOT update @backup at the same time
    def primary=(color : ImGui::ImVec4)
      @primary = color
    end

    def set_primary(color : ImGui::ImVec4)
      color.w = @primary.w
      @primary = color
      @backup = color
    end

    def set_secondary(color : ImGui::ImVec4)
      color.w = @primary.w
      @secondary = color
    end
  end
end
