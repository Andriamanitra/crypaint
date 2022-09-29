abstract class CryWidget
  abstract def show
  abstract def name_in_menu : String
  abstract def toggle_visibility
  abstract def visible? : Bool
end
