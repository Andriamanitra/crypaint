require "imgui"
require "crsfml"
require "./crywidget.cr"

module CryPaint
  class UndoWidget < CryWidget
    def initialize(shapes : Array(SF::Drawable), undo_ptr : Pointer(Int32))
      @visible = true
      @shapes = shapes
      @undo_ptr = undo_ptr
    end

    def show
      return if !@visible
      ImGui.window("Undo stack") do
        ImGui.slider_int("Undo", @undo_ptr, v_min: 0, v_max: @shapes.size)
      end
    end

    def name_in_menu : String
      "Undo stack"
    end

    def toggle_visibility
      @visible = !@visible
    end

    def visible? : Bool
      @visible
    end
  end
end
