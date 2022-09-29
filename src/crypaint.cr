require "crsfml"
require "imgui"
require "imgui-sfml"
require "./overlay_mousepos.cr"

class CryPaintWindow < SF::RenderWindow
  def initialize
    videomode = SF::VideoMode.new(1280, 720)
    title = "CryPaint ALPHA"
    settings = SF::ContextSettings.new(depth: 24, antialiasing: 0)
    super(videomode, title, settings: settings)
    @shapes = [] of SF::Drawable
    @undo_idx = 0
  end

  def draw_at(x, y)
    radius = 10
    shape = SF::CircleShape.new(radius)
    shape.move(x - radius, y - radius)
    # invalidate the current "redo" queue on draw
    if @undo_idx < @shapes.size
      @shapes.pop(@shapes.size - @undo_idx)
    end
    @shapes << shape
    @undo_idx += 1
  end

  def new_drawing
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
    if event.is_a? SF::Event::MouseMoveEvent
      if SF::Mouse.button_pressed?(SF::Mouse::Button::Left)
        coord = map_pixel_to_coords({event.x, event.y})
        draw_at(coord.x, coord.y)
      end
    end
  end

  def process_keyboard_event(event : SF::Event::KeyEvent)
    if event.control
      case event.code
      when SF::Keyboard::Key::N
        new_drawing
      when SF::Keyboard::Key::Z
        event.shift ? redo() : undo()
      end
    end
  end

  def process_events
    while (event = poll_event())
      ImGui::SFML.process_event(self, event)
      io = ImGui.get_io

      if !io.want_capture_mouse
        process_mouse_event(event)
      end

      if !io.want_capture_keyboard && event.is_a? SF::Event::KeyEvent
        process_keyboard_event(event)
      end

      close() if event.is_a? SF::Event::Closed
    end
  end

  def run
    ImGui::SFML.init(self)
    mouse_coords_visible = true
    imgui_demo_visible = false
    about_visible = false
    clock = SF::Clock.new

    while open?
      clear()
      process_events()

      ImGui::SFML.update(self, clock.restart)

      ImGui.main_menu_bar do
        ImGui.menu("File") do
          if ImGui.menu_item("New", "Ctrl+N")
            new_drawing()
          end
          ImGui.menu_item("Open", "Ctrl+O")
          ImGui.menu_item("Save", "Ctrl+S")
        end
        ImGui.menu("View") do
          if ImGui.menu_item("Mouse position", nil, mouse_coords_visible)
            mouse_coords_visible = !mouse_coords_visible
          end
          if ImGui.menu_item("ImGui demo", nil, imgui_demo_visible)
            imgui_demo_visible = !imgui_demo_visible
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
          ImGui.menu_item("Cut", "Ctrl+X")
          ImGui.menu_item("Copy", "Ctrl+C")
          ImGui.menu_item("Paste", "Ctrl+V")
        end
      end

      mouse_position_overlay() if mouse_coords_visible
      ImGui.show_demo_window if imgui_demo_visible

      @undo_idx.times do |i|
        draw(@shapes[i])
      end

      ImGui::SFML.render(self)
      display()
    end
    ImGui::SFML.shutdown
  end
end

CryPaintWindow.new.run
