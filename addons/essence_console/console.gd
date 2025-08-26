extends Node

# Simple console helpers for coloring text and formatting a linux-like prompt.
# - Normal text -> bright green (#00ff00)
# - "Red" / error text -> dark green (#006400)
# - format_prompt(user) -> "user@HOST:~$ "

@export var default_user: String = "user"

const COLOR_GREEN: String = "#00ff00"      # bright green
const COLOR_DARK_GREEN: String = "#006400" # dark green (used where "red" was before)

func _ready() -> void:
    pass

func format_prompt(user: String = "") -> String:
    """Return a simple linux-style prompt string, e.g. 'alice@MYPC:~$ '."""
    var uname = user if user != "" else default_user
    var host: String = "host"
    return "%s@%s:~$ " % [uname, host]

func colorize(text: String, kind: String = "normal") -> String:
    """Return text wrapped in BBCode color tags for RichTextLabel.
       kind: "normal" -> bright green, "error" -> dark green (used in place of red).
    """
    var col = COLOR_GREEN
    if kind == "error":
        col = COLOR_DARK_GREEN
    return "[color=%s]%s[/color]" % [col, text]

func apply_to_richtext(rt: RichTextLabel, text: String, kind: String = "normal") -> void:
    """Helper to append colored text to a RichTextLabel using BBCode.
       Enables BBCode on the label if necessary.
    """
    if not rt:
        return
    rt.bbcode_enabled = true
    rt.append_bbcode(colorize(text, kind))
