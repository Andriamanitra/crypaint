require "crsfml"
require "imgui"
require "imgui-sfml"
require "./widgets/*"
require "./colors.cr"

module CryPaint
  include ImGui::TopLevel

  class CryPaintWindow < SF::RenderWindow
    def initialize
      @width = 1280
      @height = 720
      videomode = SF::VideoMode.new(@width, @height)
      title = "CryPaint ALPHA"
      settings = SF::ContextSettings.new(depth: 24, antialiasing: 0)
      super(videomode, title, settings: settings)
      @shapes = [] of SF::Drawable
      @undo_idx = 0
      @colors = CryPaint::Colors.new
      @imagetex = SF::Texture.new
      @sprite = SF::Sprite.new(@imagetex)
      @has_image = false
      # Workaround for https://github.com/ocornut/imgui/issues/331
      @file_open_dialog_visible = false
      # TODO: refactor the mouse handling business to separate class
      @mouse_wheel_speed = 0.1
      @mouse_drag_start = Hash(SF::Mouse::Button, SF::Vector2i).new
      @widgets = [] of CryWidget
      @widgets << ColorsWidget.new(@colors)
      @widgets << MousePosWidget.new
      @widgets << SpecialFxWidget.new(self, @colors)
      self.framerate_limit = 120
    end

    def center_view
      self.view.center = {0.5 * @width, 0.5 * @height}
      centerw = (@imagetex.size.x - @width) / 2
      centerh = (@imagetex.size.y - @height) / 2
      self.view.move(centerw, centerh)
    end

    def load_image(image : SF::Image) : Bool
      if success = @imagetex.load_from_image(image)
        new_drawing()
        @sprite.set_texture(@imagetex, reset_rect: true)
        center_view()
        @has_image = true
      end
      success
    end

    def load_image(filepath : String) : Bool
      if success = @imagetex.load_from_file(filepath)
        new_drawing()
        @sprite.set_texture(@imagetex, reset_rect: true)
        center_view()
        @has_image = true
      end
      success
    end

    def register_widget(widget : CryWidget)
      @widgets << widget
    end

    def draw_at(x, y, color : ImVec4 = @colors.primary)
      radius = 10
      r = (color.x * 255).to_i
      g = (color.y * 255).to_i
      b = (color.z * 255).to_i
      alpha = (@colors.primary.w * 255).to_i
      shape = SF::CircleShape.new(radius)
      shape.fill_color = SF::Color.new(r, g, b, alpha)
      shape.move(x - radius, y - radius)
      # invalidate the current "redo" queue on draw
      if @undo_idx < @shapes.size
        @shapes.pop(@shapes.size - @undo_idx)
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
        # TODO: zooming doesn't quite focus on the right point
        dx = (event.x - 0.5 * @width) * event.delta * @mouse_wheel_speed
        dy = (event.y - 0.5 * @height) * event.delta * @mouse_wheel_speed
        self.view.move(dx, dy)
        self.view.zoom(1 - @mouse_wheel_speed * event.delta)
      elsif event.is_a? SF::Event::MouseButtonPressed
        @mouse_drag_start[event.button] = SF::Vector2i.new(event.x, event.y)
      end
    end

    def process_keyboard_event(event : SF::Event::KeyEvent)
      if event.control
        case event.code
        when SF::Keyboard::Key::O
          @file_open_dialog_visible = true
        when SF::Keyboard::Key::N
          new_drawing
        when SF::Keyboard::Key::Z
          event.shift ? redo() : undo()
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
      if !io.want_capture_mouse
        mousepos = SF::Mouse.get_position(relative_to: self)
        coord = map_pixel_to_coords(mousepos)
        if SF::Mouse.button_pressed?(SF::Mouse::Button::Left)
          draw_at(coord.x, coord.y, @colors.primary)
        elsif SF::Mouse.button_pressed?(SF::Mouse::Button::Right)
          draw_at(coord.x, coord.y, @colors.secondary)
        elsif SF::Mouse.button_pressed?(SF::Mouse::Button::Middle)
          previous_pos = @mouse_drag_start[SF::Mouse::Button::Middle]
          prevcoord = map_pixel_to_coords(previous_pos)
          self.view.move(prevcoord - coord)
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
