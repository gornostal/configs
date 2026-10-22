# Minimize the OS window of the active kitty window. Used by bin/kitty-toggle:
#   kitten @ kitten minimize.py
# kitty's own hide (resize-os-window --action=hide) unmaps the Wayland surface, and Gala
# doesn't reliably show it again; a minimized window can be restored by the compositor.
from kittens.tui.handler import result_handler
from kitty.fast_data_types import WINDOW_MINIMIZED, change_os_window_state


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: None, target_window_id: int, boss) -> None:
    w = boss.window_id_map.get(target_window_id)
    change_os_window_state(WINDOW_MINIMIZED, w.os_window_id if w else 0)
