require "crsfml"
require "./crywidget"
require "../colors"

module CryPaint
  class SpecialFxWidget < CryWidget
    def initialize(window : CryPaint::CryPaintWindow, colors : CryPaint::Colors)
      @window = window
      @colors = colors
      @visible = false
      @vx = 0_f32
      @vy = 0_f32
      @vrot = 0_f32
      @vzoom = 0_f32
      @rng = Random.new
      @rng_colors_enabled = false
      @color_variance = ImVec4.new(0.004_f32, 0.004_f32, 0.004_f32, 0_f32)
      @color_variance_momentum = ImVec4.new
      @momentum_factor = 0.01_f32
      @stored_view_state = @window.view.dup
    end

    def reset_view
      @window.view = @stored_view_state.dup
    end

    def reset_settings
      @vx = 0_f32
      @vy = 0_f32
      @vrot = 0_f32
      @vzoom = 0_f32
      @rng_colors_enabled = false
      @color_variance = ImVec4.new(0.004_f32, 0.004_f32, 0.004_f32, 0_f32)
      @color_variance_momentum = ImVec4.new
      @momentum_factor = 0.01_f32
    end

    def show
      return if !@visible

      # apply all the nonsense
      @window.view.move(-@vx, -@vy)
      @window.view.rotate(@vrot)
      @window.view.zoom(1 + 0.003 * @vzoom)
      if @rng_colors_enabled
        dr = @color_variance_momentum.x + @rng.rand(-1_f32..1_f32) * @color_variance.x
        r = @colors.primary.x + dr
        @colors.primary.x = r.clamp(0_f32, 1_f32)
        if 0 < @colors.primary.x < 1
          @color_variance_momentum.x += @momentum_factor * dr
        else
          @color_variance_momentum.x = 0_f32
        end

        dg = @color_variance_momentum.y + @rng.rand(-1_f32..1_f32) * @color_variance.y
        g = @colors.primary.y + dg
        @colors.primary.y = g.clamp(0_f32, 1_f32)
        if 0 < @colors.primary.y < 1
          @color_variance_momentum.y += @momentum_factor * dg
        else
          @color_variance_momentum.y = 0_f32
        end

        db = @color_variance_momentum.z + @rng.rand(-1_f32..1_f32) * @color_variance.z
        b = @colors.primary.z + db
        @colors.primary.z = b.clamp(0_f32, 1_f32)
        if 0 < @colors.primary.z < 1
          @color_variance_momentum.z += @momentum_factor * db
        else
          @color_variance_momentum.z = 0_f32
        end

        da = @color_variance_momentum.w + @rng.rand(-1_f32..1_f32) * @color_variance.w
        a = @colors.primary.w + da
        @colors.primary.w = a.clamp(0_f32, 1_f32)
        if 0 < @colors.primary.w < 1
          @color_variance_momentum.w += @momentum_factor * da
        else
          @color_variance_momentum.w = 0_f32
        end
      end

      ImGui.window("Special FX", flags: ImGuiWindowFlags::NoFocusOnAppearing) do
        ImGui.slider_float("Vx", pointerof(@vx), -1_f32, 1_f32)
        ImGui.slider_float("Vy", pointerof(@vy), -1_f32, 1_f32)
        ImGui.slider_float("Vrot", pointerof(@vrot), -1_f32, 1_f32)
        ImGui.slider_float("Vzoom", pointerof(@vzoom), -1_f32, 1_f32)
        ImGui.checkbox("Randomize colors", pointerof(@rng_colors_enabled))
        ImGui.drag_float4("Color variance", pointerof(@color_variance), v_speed: 0.001_f32, v_min: 0_f32, v_max: 1_f32)
        ImGui.drag_float("Color change momentum", pointerof(@momentum_factor), 0.0001_f32)
        if ImGui.button("Reset position")
          reset_view()
        end
        ImGui.same_line
        if ImGui.button("Reset settings")
          reset_settings()
        end
      end
    end

    def name_in_menu : String
      "Special FX"
    end

    def toggle_visibility
      if @visible
        # return view back to normal when closing the special fx window
        reset_view()
      else
        @stored_view_state = @window.view.dup
      end
      @visible = !@visible
    end

    def visible? : Bool
      @visible
    end
  end
end
