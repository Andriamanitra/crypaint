require "crsfml"
require "imgui"
require "imgui-sfml"
require "./widgets/*"
require "./colors.cr"

module CryPaint
  include ImGui::TopLevel

  class CryPaintWindow < SF::RenderWindow
    @@MIN_VIEW_SIZE = 10_f32
    @@MAX_VIEW_SIZE = 100000_f32

    def initialize
      videomode = SF::VideoMode.new(1280, 720)
      title = "CryPaint ALPHA"
      settings = SF::ContextSettings.new(depth: 24, antialiasing: 0)
      super(videomode, title, settings: settings)
      @shapes = [] of SF::Drawable
      @selected_shape = SF::CircleShape
      @undo_idx = 0
      @colors = CryPaint::Colors.new
      @draw_radius = 10
      @imagetex = SF::Texture.new
      @sprite = SF::Sprite.new(@imagetex)
      @has_image = false
      # Workaround for https://github.com/ocornut/imgui/issues/331
      @file_open_dialog_visible = false
      # TODO: refactor the mouse handling business to separate class
      @zoom_factor = 1.05
      @mouse_drag_start = Hash(SF::Mouse::Button, SF::Vector2i).new
      @previous_draw = Hash(SF::Mouse::Button, SF::Vector2f).new
      @widgets = [] of CryWidget
      @widgets << ColorsWidget.new(@colors)
      @widgets << MousePosWidget.new
      @widgets << SpecialFxWidget.new(self, @colors)
      @widgets << ToolsWidget.new(pointerof(@draw_radius))
      @widgets << UndoWidget.new(@shapes, pointerof(@undo_idx))
      self.framerate_limit = 120
      center_view()
    end

    def center_view
      self.view.center = {0, 0}
    end

    def load_image(image : SF::Image) : Bool
      if success = @imagetex.load_from_image(image)
        new_drawing()
        @sprite.set_texture(@imagetex, reset_rect: true)
        @sprite.origin = @imagetex.size / 2
        center_view()
        @has_image = true
      end
      success
    end

    def load_image(filepath : String) : Bool
      if success = @imagetex.load_from_file(filepath)
        new_drawing()
        @sprite.set_texture(@imagetex, reset_rect: true)
        @sprite.origin = @imagetex.size / 2
        center_view()
        @has_image = true
      end
      success
    end

    def register_widget(widget : CryWidget)
      @widgets << widget
    end

    def draw_between(prev, curr, color : ImVec4 = @colors.primary)
      r = (color.x * 255).to_i
      g = (color.y * 255).to_i
      b = (color.z * 255).to_i
      alpha = (@colors.primary.w * 255).to_i
      sf_color = SF::Color.new(r, g, b, alpha)
      delta = curr - prev
      dist = Math.hypot(delta.x, delta.y)
      if dist > @draw_radius * 0.5_f32
        # interpolate some more dots in between
        steps = (2 * dist / @draw_radius).ceil.to_i
        steps.times do |i|
          c = prev + delta * ((i + 0.5) / steps)
          draw_dot(c.x, c.y, sf_color)
        end
      end
      draw_dot(curr.x, curr.y, sf_color)
    end

    def draw_dot(x, y, color : SF::Color)
      shape = @selected_shape.new(@draw_radius)
      shape.fill_color = color
      shape.move(x - @draw_radius, y - @draw_radius)
      # invalidate the current "redo" queue on draw
      if @undo_idx < @shapes.size
        @shapes.pop(@shapes.size - @undo_idx)
      end
      unless @shapes.empty?
        last_shape = @shapes[@undo_idx - 1]
        return if (
          last_shape.is_a? SF::CircleShape &&
          shape.transform == last_shape.transform &&
          shape.fill_color == last_shape.fill_color &&
          shape.radius == last_shape.radius
        )
      end
      @shapes << shape
      @undo_idx += 1
    end

    def new_drawing
      @has_image = false
      @shapes.clear
      @undo_idx = 0
    end

    def undo
      @undo_idx -= 1 if @undo_idx > 0
    end

    def redo
      @undo_idx += 1 if @undo_idx < @shapes.size
    end

    def process_mouse_event(event : SF::Event)
      if event.is_a? SF::Event::MouseWheelScrollEvent
        before = map_pixel_to_coords({event.x, event.y})
        return if event.delta > 0 && self.view.size.y < @@MIN_VIEW_SIZE
        return if event.delta < 0 && self.view.size.y > @@MAX_VIEW_SIZE

        self.view.zoom(@zoom_factor ** -event.delta)
        after = map_pixel_to_coords({event.x, event.y})
        self.view.move(before - after)
      elsif event.is_a? SF::Event::MouseButtonPressed
        @mouse_drag_start[event.button] = SF::Vector2i.new(event.x, event.y)
      elsif event.is_a? SF::Event::MouseButtonReleased
        @mouse_drag_start.delete(event.button)
        @previous_draw.delete(event.button)
      end
    end

    def process_keyboard_event(event : SF::Event::KeyEvent)
      if event.control
        case event.code
        when SF::Keyboard::Key::O
          @file_open_dialog_visible = true
        when SF::Keyboard::Key::Q
          exit
        when SF::Keyboard::Key::N
          new_drawing
        when SF::Keyboard::Key::Z
          event.shift ? redo() : undo()
        when SF::Keyboard::Key::Add
          self.view.zoom(1 / @zoom_factor)
        when SF::Keyboard::Key::Subtract
          self.view.zoom(@zoom_factor)
        when SF::Keyboard::Key::Numpad0
          self.view.size = {size.x, size.y}
        when SF::Keyboard::Key::Numpad5
          center_view()
        end
      end
    end

    def process_events
      io = ImGui.get_io
      while (event = poll_event())
        ImGui::SFML.process_event(self, event)

        if !io.want_capture_mouse
          process_mouse_event(event)
        end

        if !io.want_capture_keyboard && event.is_a? SF::Event::KeyEvent
          process_keyboard_event(event)
        end

        close() if event.is_a? SF::Event::Closed
      end
      # Handle mouse keys being held down
      if !io.want_capture_mouse && focus?
        mousepos = SF::Mouse.get_position(relative_to: self)
        coord = map_pixel_to_coords(mousepos)

        # only when mouse inside the current window
        if 0 < mousepos.x < size.x && 0 < mousepos.y < size.y
          if SF::Mouse.button_pressed?(SF::Mouse::Button::Left)
            if previous_coord = @previous_draw[SF::Mouse::Button::Left]?
              draw_between(previous_coord, coord, @colors.primary)
            end
            @previous_draw[SF::Mouse::Button::Left] = coord
          end
          if SF::Mouse.button_pressed?(SF::Mouse::Button::Right)
            if previous_coord = @previous_draw[SF::Mouse::Button::Right]?
              draw_between(previous_coord, coord, @colors.secondary)
            end
            @previous_draw[SF::Mouse::Button::Right] = coord
          end
        end

        if SF::Mouse.button_pressed?(SF::Mouse::Button::Middle)
          if previous_pos = @mouse_drag_start[SF::Mouse::Button::Middle]?
            prevcoord = map_pixel_to_coords(previous_pos)
            self.view.move(prevcoord - coord)
          end
          @mouse_drag_start[SF::Mouse::Button::Middle] = mousepos
        end
      end
    end

    def run
      ImGui::SFML.init(self)
      imgui_demo_visible = false
      clock = SF::Clock.new
      @file_open_dialog_visible = false

      while open?
        clear()
        process_events()

        ImGui::SFML.update(self, clock.restart)

        ImGui.main_menu_bar do
          ImGui.menu("File") do
            if ImGui.menu_item("New", "Ctrl+N")
              new_drawing()
            end
            if ImGui.menu_item("Open", "Ctrl+O")
              @file_open_dialog_visible = true
            end
            ImGui.menu_item("(TODO) Save", "Ctrl+S")
          end
          ImGui.menu("View") do
            if ImGui.menu_item("ImGui demo", nil, imgui_demo_visible)
              imgui_demo_visible = !imgui_demo_visible
            end
            @widgets.each do |widget|
              if ImGui.menu_item(widget.name_in_menu, nil, widget.visible?)
                widget.toggle_visibility
              end
            end
          end
          ImGui.menu("Edit") do
            if ImGui.menu_item("Undo", "Ctrl+Z")
              undo()
            end
            if ImGui.menu_item("Redo", "Ctrl+Shift+Z")
              redo()
            end
            ImGui.separator
            ImGui.menu_item("(TODO) Cut", "Ctrl+X")
            ImGui.menu_item("(TODO) Copy", "Ctrl+C")
            ImGui.menu_item("(TODO) Paste", "Ctrl+V")
          end
        end

        # Conditionally rendered ImGui elements
        ImGui.show_demo_window if imgui_demo_visible
        if @file_open_dialog_visible
          ImGui.open_popup("Open file..")
          center = ImGui.get_main_viewport.get_center
          modal_flags = ImGuiWindowFlags::AlwaysAutoResize
          ImGui.set_next_window_pos(center, ImGuiCond::Appearing, ImVec2.new(0.5f32, 0.5f32))

          ImGui.popup_modal("Open file..", flags: modal_flags) do
            # TODO: ImGui.input_text
            if ImGui.button("Cancel", ImVec2.new(120, 0))
              ImGui.close_current_popup
              @file_open_dialog_visible = false
            end
            ["test.png", "test2.png", "test3.png"].each do |fname|
              ImGui.same_line
              if ImGui.button(fname, ImVec2.new(120, 0))
                if load_image(fname)
                  ImGui.close_current_popup
                  @file_open_dialog_visible = false
                end
              end
            end
          end
        end

        @widgets.each(&.show)

        draw(@sprite) if @has_image

        @undo_idx.times do |i|
          draw(@shapes[i])
        end

        ImGui::SFML.render(self)
        display()
      end
      ImGui::SFML.shutdown
    end
  end
end

CryPaint::CryPaintWindow.new.run
