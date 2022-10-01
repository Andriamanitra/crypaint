require "imgui"
require "crsfml"
require "./crywidget.cr"

DEFAULT_CODE = <<-EOF
void main() {
  gl_Position = vec4(0., 0., 0., 0.);
}
EOF

module CryPaint
  class ShaderWidget < CryWidget
    def initialize(shader : Pointer(SF::Shader?))
      @visible = false
      @shader = shader
      @textbuf = ImGui::TextBuffer.new(1024*16)
      @textbuf.write(DEFAULT_CODE.to_slice)
      @status = "No shader applied"
    end

    def show
      return if !@visible

      ImGui.input_text_multiline("##glsl_editor", @textbuf)
      if ImGui.button("Apply")
        glsl_source_code = @textbuf.to_slice.map(&.chr).to_a.join
        begin
          shader = SF::Shader.from_memory(glsl_source_code, SF::Shader::Type::Vertex)
          @shader.value = shader
          @status = "SUCCESS?"
        rescue SF::InitError
          @status = "FAILED TO COMPILE, WRITE BETTER CODE PLS"
        end
      end
      ImGui.text("Status: #{@status}")
    end

    def name_in_menu : String
      "Shaders"
    end

    def toggle_visibility
      @visible = !@visible
    end

    def visible? : Bool
      @visible
    end
  end
end
