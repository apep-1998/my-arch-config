import asyncio
import os
import subprocess

from i3ipc import Event
from i3ipc.aio import Connection

# Store layout preference per container ID (i3 internal ID)
# Format: { container_id: 'layout_code' }
WINDOW_LAYOUTS = {}
LAYOUT_ORDER = ["us", "ir"]


def set_xkb_layout(primary_layout):
    """
    Sets the global keyboard layout using setxkbmap.
    Constructs the layout list such that 'primary_layout' is the first one active.
    """
    # Create a list starting with the primary layout, followed by others
    layouts = [primary_layout] + [l for l in LAYOUT_ORDER if l != primary_layout]
    layout_str = ",".join(layouts)

    subprocess.run(["setxkbmap", "-layout", layout_str])


def toggle_layout(container_id):
    """
    Toggles the stored layout for the specific container ID and applies it immediately.
    """
    current_layout = WINDOW_LAYOUTS.get(container_id, "us")

    # Calculate next layout index
    try:
        idx = LAYOUT_ORDER.index(current_layout)
    except ValueError:
        idx = 0

    next_idx = (idx + 1) % len(LAYOUT_ORDER)
    new_layout = LAYOUT_ORDER[next_idx]

    # Update storage and apply
    WINDOW_LAYOUTS[container_id] = new_layout
    print(f"Window {container_id} layout toggled to: {new_layout}")
    set_xkb_layout(new_layout)


def on_window_focus(i3, e):
    """
    When a window is focused, restore its saved layout.
    """
    container_id = e.container.id

    # Retrieve saved layout, default to 'us' if unknown
    layout = WINDOW_LAYOUTS.get(container_id, "us")

    # Ensure we track this window if we weren't already (safety catch)
    if container_id not in WINDOW_LAYOUTS:
        WINDOW_LAYOUTS[container_id] = layout

    # Apply the window's specific layout
    set_xkb_layout(layout)


def on_new_window(i3, e):
    """
    When a new window is created, initialize it to 'us' (EN).
    """
    container_id = e.container.id
    print(
        f"New window created: {e.container.name} (ID: {container_id}) -> Defaulting to 'us'"
    )
    WINDOW_LAYOUTS[container_id] = "us"
    # Note: The focus event usually triggers immediately after this,
    # which will actually apply the 'us' layout via on_window_focus.


def on_close_window(i3, e):
    """
    Clean up memory when a window is closed.
    """
    container_id = e.container.id
    if container_id in WINDOW_LAYOUTS:
        del WINDOW_LAYOUTS[container_id]


async def on_tick(i3, e):
    """
    Listen for custom events (e.g., from i3 config binds) to toggle layout.
    Payloads expected:
      - "CHANGE_KEYBOARD_LAYOUT"
      - "FORCE_US_LAYOUT_START"
      - "FORCE_US_LAYOUT_END"
    """
    payload = e.payload

    if payload.startswith("CHANGE_KEYBOARD_LAYOUT"):
        tree = await i3.get_tree()
        focused = tree.find_focused()
        if focused:
            toggle_layout(focused.id)

    elif payload == "FORCE_US_LAYOUT_START":
        print("Force 'us' layout start")
        set_xkb_layout("us")

    elif payload == "FORCE_US_LAYOUT_END":
        tree = await i3.get_tree()
        focused = tree.find_focused()
        if focused:
            layout = WINDOW_LAYOUTS.get(focused.id, "us")
            print(
                f"Force 'us' layout end -> Restoring window {focused.id} layout: {layout}"
            )
            set_xkb_layout(layout)


_polybar_relaunch_task = None


async def _relaunch_polybar_after_settle():
    """Wait briefly so a burst of OUTPUT events collapses into one relaunch."""
    try:
        await asyncio.sleep(0.5)
    except asyncio.CancelledError:
        return
    print("Output configuration settled -> relaunching polybar")
    subprocess.Popen(
        [os.path.expanduser("~/.config/polybar/launch.sh")],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def on_output_change(i3, e):
    """
    Re-launch polybar whenever the monitor configuration changes
    (connect, disconnect, reposition) so a bar appears on every new
    output and stale instances get cleaned up.
    """
    global _polybar_relaunch_task
    if _polybar_relaunch_task and not _polybar_relaunch_task.done():
        _polybar_relaunch_task.cancel()
    _polybar_relaunch_task = asyncio.create_task(_relaunch_polybar_after_settle())


async def main():
    i3 = await Connection().connect()

    i3.on(Event.WINDOW_FOCUS, on_window_focus)
    i3.on(Event.WINDOW_NEW, on_new_window)
    i3.on(Event.WINDOW_CLOSE, on_close_window)
    i3.on(Event.TICK, on_tick)
    i3.on(Event.OUTPUT, on_output_change)

    await i3.main()


if __name__ == "__main__":
    asyncio.run(main())
