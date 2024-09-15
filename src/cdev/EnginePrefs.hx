package cdev;

class EnginePrefs {
    public static var keybinds:{
        left:Array<String>, down:Array<String>, up:Array<String>, right:Array<String>, // notes
        ui_left:Array<String>, ui_down:Array<String>, ui_up:Array<String>, ui_right:Array<String>, // ui
        accept:Array<String>, back:Array<String>, pause:Array<String>, reset:Array<String> // basic stuff
    } = {
        left: ["LEFT", "D"],
        down: ["DOWN", "F"],
        up: ["UP", "J"],
        right: ["RIGHT", "K"],
        
        ui_left: ["LEFT", "A"],
        ui_down: ["DOWN", "S"],
        ui_up: ["UP", "W"],
        ui_right: ["RIGHT", "D"],
        
        accept: ["ENTER", "SPACE"],
        back: ["ESCAPE", "BACKSPACE"],
        pause: ["ENTER", "ESCAPE"],
        reset: ["R", "F5"]
    };
}
