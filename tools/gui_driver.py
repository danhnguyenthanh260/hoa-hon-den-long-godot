import argparse
import ctypes
import json
import os
import subprocess
import time
from ctypes import wintypes

import pyautogui


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GODOT = os.path.join(ROOT, "tools", "Godot_v4.5-stable_win64.exe")
STATE_PATH = os.path.join(ROOT, "shots", "gui_state.json")
PLAY = 1
DIALOGUE = 3
WON = 5

user32 = ctypes.windll.user32
EnumWindowsProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

user32.SetWindowPos.argtypes = [
    wintypes.HWND,
    wintypes.HWND,
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_uint,
]
user32.ShowWindow.argtypes = [wintypes.HWND, ctypes.c_int]
user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
user32.GetWindowTextLengthW.argtypes = [wintypes.HWND]
user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]

SW_RESTORE = 9
HWND_TOPMOST = wintypes.HWND(-1)
SWP_SHOWWINDOW = 0x0040


def window_title(hwnd: int) -> str:
    length = user32.GetWindowTextLengthW(hwnd)
    if length <= 0:
        return ""
    buffer = ctypes.create_unicode_buffer(length + 1)
    user32.GetWindowTextW(hwnd, buffer, length + 1)
    return buffer.value


def find_window_for_pid(pid: int) -> int | None:
    found: list[int] = []

    def callback(hwnd: int, _lparam: int) -> bool:
        win_pid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(win_pid))
        if win_pid.value == pid and user32.IsWindowVisible(hwnd) and window_title(hwnd):
            found.append(hwnd)
        return True

    user32.EnumWindows(EnumWindowsProc(callback), 0)
    return found[0] if found else None


def rect(hwnd: int) -> tuple[int, int, int, int]:
    value = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(value))
    return value.left, value.top, value.right, value.bottom


def bring_to_front(hwnd: int, width: int, height: int) -> tuple[int, int, int, int]:
    user32.ShowWindow(hwnd, SW_RESTORE)
    user32.SetWindowPos(hwnd, HWND_TOPMOST, 100, 100, width, height, SWP_SHOWWINDOW)
    time.sleep(0.6)
    l, t, r, b = rect(hwnd)
    pyautogui.click(l + (r - l) // 2, t + (b - t) // 2)
    time.sleep(0.25)
    return rect(hwnd)


def screenshot(hwnd: int, path: str) -> None:
    l, t, r, b = rect(hwnd)
    image = pyautogui.screenshot(region=(l, t, r - l, b - t))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)


def launch(args: argparse.Namespace, user_args: list[str] | None = None) -> tuple[subprocess.Popen, int]:
    cmd = [GODOT, "--path", ROOT, "--resolution", f"{args.width}x{args.height}"]
    if user_args:
        cmd += ["--", *user_args]
    proc = subprocess.Popen(
        cmd,
        cwd=ROOT,
    )
    hwnd = None
    for _ in range(120):
        hwnd = find_window_for_pid(proc.pid)
        if hwnd:
            break
        time.sleep(0.25)
    if not hwnd:
        proc.terminate()
        raise RuntimeError("Godot window not found")
    bring_to_front(hwnd, args.width, args.height)
    return proc, hwnd


def read_state(timeout: float = 5.0) -> dict:
    deadline = time.time() + timeout
    last_error: Exception | None = None
    while time.time() < deadline:
        try:
            with open(STATE_PATH, "r", encoding="utf-8") as fh:
                raw = fh.read().strip()
            if raw:
                return json.loads(raw)
        except Exception as exc:
            last_error = exc
        time.sleep(0.05)
    raise RuntimeError(f"telemetry state unavailable: {last_error}")


def wait_until(label: str, predicate, timeout: float = 30.0) -> dict:
    deadline = time.time() + timeout
    last: dict = {}
    while time.time() < deadline:
        last = read_state(2.0)
        if predicate(last):
            return last
        time.sleep(0.1)
    raise RuntimeError(f"timeout waiting for {label}: {last}")


def release_movement() -> None:
    for key in ["w", "a", "s", "d", "shift"]:
        pyautogui.keyUp(key)


def clear_dialogue(timeout: float = 45.0) -> dict:
    deadline = time.time() + timeout
    last: dict = {}
    while time.time() < deadline:
        last = read_state(2.0)
        panels_active = (
            last.get("dialogue_active")
            or last.get("memory_stall_active")
            or last.get("memorial_tablet_active")
        )
        if last.get("state") == PLAY and not panels_active:
            return last
        if last.get("state") == WON:
            return last
        if last.get("dialogue_waiting_choice"):
            pyautogui.press("1")
        elif last.get("state") == 4:
            pyautogui.keyDown("space")
            time.sleep(0.9)
            pyautogui.keyUp("space")
        elif not last.get("memory_stall_active") and not last.get("memorial_tablet_active"):
            pyautogui.press("space")
        time.sleep(0.18)
    raise RuntimeError(f"timeout clearing dialogue/panels: {last}")


def snapshot(hwnd: int, name: str) -> None:
    screenshot(hwnd, os.path.join(ROOT, "shots", f"gui_e2e_{name}.png"))


def set_follow_view() -> None:
    clear_dialogue()
    pyautogui.press("v")
    time.sleep(0.2)
    pyautogui.press("v")
    time.sleep(0.3)
    clear_dialogue()


def move_to(x: float, z: float, label: str, tol: float = 0.45, timeout: float = 35.0) -> dict:
    deadline = time.time() + timeout
    last: dict = {}
    while time.time() < deadline:
        last = read_state(2.0)
        if last.get("state") != PLAY:
            release_movement()
            clear_dialogue()
            continue
        dx = x - float(last["x"])
        dz = z - float(last["z"])
        if abs(dx) <= tol and abs(dz) <= tol:
            release_movement()
            return last
        keys: list[str] = []
        if abs(dx) > tol:
            keys.append("d" if dx > 0 else "a")
        if abs(dz) > tol:
            keys.append("s" if dz > 0 else "w")
        for key in keys:
            pyautogui.keyDown(key)
        step = min(0.15, max(0.03, max(abs(dx), abs(dz)) / 6.0))
        time.sleep(step)
        release_movement()
    release_movement()
    raise RuntimeError(f"timeout moving to {label} ({x:.1f},{z:.1f}): {last}")


def interact_at(hwnd: int, x: float, z: float, label: str, tol: float = 0.45) -> dict:
    state = move_to(x, z, label, tol=tol)
    prompt = str(state.get("prompt", "")).encode("ascii", "replace").decode("ascii")
    print(f"{label}: prompt={prompt!r} pos=({state.get('x'):.2f},{state.get('z'):.2f})")
    original_prompt = state.get("prompt", "")
    for _ in range(3):
        pyautogui.press("e")
        time.sleep(0.25)
        after = read_state(2.0)
        panels_active = (
            after.get("dialogue_active")
            or after.get("memory_stall_active")
            or after.get("memorial_tablet_active")
        )
        if after.get("state") != PLAY or panels_active or after.get("prompt", "") != original_prompt:
            break
    clear_dialogue()
    if label.endswith("checkpoint"):
        snapshot(hwnd, label.replace(" ", "_"))
    return read_state(2.0)


def wait_chapter(chapter: int, timeout: float = 60.0) -> dict:
    deadline = time.time() + timeout
    last: dict = {}
    while time.time() < deadline:
        last = read_state(2.0)
        if last.get("chapter") == chapter and last.get("state") == PLAY:
            return clear_dialogue()
        if last.get("state") != PLAY:
            release_movement()
            clear_dialogue()
        time.sleep(0.1)
    raise RuntimeError(f"timeout waiting for chapter {chapter}: {last}")


def trigger_c2_gate_loop(label: str) -> None:
    print(label)
    deadline = time.time() + 30.0
    saw_gate = False
    while time.time() < deadline:
        state = read_state(2.0)
        if state.get("state") != PLAY:
            release_movement()
            clear_dialogue()
            if float(read_state(2.0).get("z", -99.0)) > -25.0:
                return
        z = float(state["z"])
        if z < -42.0:
            saw_gate = True
        if saw_gate and z > -25.0:
            release_movement()
            clear_dialogue()
            return
        pyautogui.keyDown("w")
        time.sleep(0.1)
        pyautogui.keyUp("w")
    release_movement()
    raise RuntimeError(f"timeout triggering {label}: {read_state(2.0)}")


def walk_to_next_chapter(chapter: int, label: str, timeout: float = 45.0) -> dict:
    print(label)
    deadline = time.time() + timeout
    while time.time() < deadline:
        state = read_state(2.0)
        if state.get("chapter") == chapter:
            release_movement()
            return wait_chapter(chapter, timeout=60.0)
        if state.get("state") != PLAY:
            release_movement()
            clear_dialogue()
        else:
            pyautogui.keyDown("w")
            time.sleep(0.1)
            pyautogui.keyUp("w")
    release_movement()
    raise RuntimeError(f"timeout walking to chapter {chapter} via {label}: {read_state(2.0)}")


def resolve_c3_memory_vine(hwnd: int) -> None:
    interact_at(hwnd, 56.0, -37.5, "c3 reunite memories", tol=0.28)
    wait_until(
        "c3 memories reunite",
        lambda state: bool(state.get("c3_photo_revealed")),
        timeout=12.0,
    )


def run_probe(args: argparse.Namespace) -> None:
    proc, hwnd = launch(args)
    try:
        pyautogui.press("space")
        time.sleep(args.seconds)
        screenshot(hwnd, os.path.join(ROOT, "shots", "gui_input_probe.png"))
        print("GUI PROBE OK")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)


def run_launch(args: argparse.Namespace) -> None:
    proc, hwnd = launch(args)
    print(f"GUI LAUNCHED pid={proc.pid} hwnd={hwnd} title={window_title(hwnd)!r}")
    if args.keep_open:
        return
    proc.terminate()
    proc.wait(timeout=5)


def run_playthrough(args: argparse.Namespace) -> None:
    if os.path.exists(STATE_PATH):
        os.remove(STATE_PATH)
    proc, hwnd = launch(args, ["--gui-telemetry"])
    try:
        pyautogui.press("space")
        time.sleep(0.35)
        pyautogui.keyDown("space")
        time.sleep(0.95)
        pyautogui.keyUp("space")
        clear_dialogue(timeout=80.0)
        wait_chapter(1, timeout=80.0)
        clear_dialogue(timeout=20.0)
        snapshot(hwnd, "c1_first_person")
        pyautogui.press("v")
        time.sleep(0.45)
        snapshot(hwnd, "c1_third_person")
        pyautogui.press("v")
        time.sleep(0.3)
        clear_dialogue()

        interact_at(hwnd, -3.15, -11.05, "c1 talk ba")
        interact_at(hwnd, -1.92, -12.08, "c1 offer tea", tol=0.28)
        interact_at(hwnd, -5.2, -12.6, "c1 unlock house")
        interact_at(hwnd, -8.2, -14.6, "c1 collect stencil")
        interact_at(hwnd, -7.4, -17.6, "c1 take hoa")
        pyautogui.press("1")
        time.sleep(0.2)
        interact_at(hwnd, -8.2, -17.25, "c1 burn seal", tol=0.12)
        snapshot(hwnd, "c1_done")
        interact_at(hwnd, -8.2, -17.9, "c1 descend", tol=0.12)
        wait_chapter(2, timeout=80.0)
        clear_dialogue(timeout=20.0)
        # Follow -> first -> third -> follow: lưu ảnh đúng sau khi V nhận input ở trạng thái PLAY.
        pyautogui.press("v")
        time.sleep(0.35)
        snapshot(hwnd, "c2_entry_first_person")
        pyautogui.press("v")
        time.sleep(0.45)
        snapshot(hwnd, "c2_entry_third_person")
        pyautogui.press("v")
        time.sleep(0.30)
        snapshot(hwnd, "c2_start")

        interact_at(hwnd, 0.0, -42.65, "c2 inspect closed gate", tol=0.30)
        snapshot(hwnd, "c2_gate_closed")
        interact_at(hwnd, 0.0, -23.8, "c2 talk child")
        interact_at(hwnd, -3.25, -28.0, "c2 look left well")
        interact_at(hwnd, 3.25, -28.0, "c2 look right well")
        interact_at(hwnd, 3.25, -28.0, "c2 choose remembering well")
        interact_at(hwnd, 3.25, -29.35, "c2 take thuy", tol=0.18)
        interact_at(hwnd, 1.35, -23.68, "c2 take lotus", tol=0.18)
        pyautogui.press("2")
        time.sleep(0.2)
        wait_until("Thuy color selected", lambda s: s.get("current_color") == "thuy", timeout=5.0)
        interact_at(hwnd, 3.25, -28.0, "c2 offer lotus", tol=0.22)
        move_to(0.0, -42.65, "c2 inspect open gate", tol=0.30)
        snapshot(hwnd, "c2_gate_open")
        interact_at(hwnd, 0.0, -42.65, "c2 cross gate", tol=0.30)
        wait_chapter(3, timeout=80.0)
        snapshot(hwnd, "c3_start")

        interact_at(hwnd, 59.1, -38.0, "c3 take moc")
        pyautogui.press("3")
        time.sleep(0.2)
        interact_at(hwnd, 53.8, -33.0, "c3 grow vines", tol=0.55)
        move_to(54.0, -38.2, "c3 climb vines", tol=0.35, timeout=45.0)
        move_to(56.0, -37.5, "c3 inspect memory knot", tol=0.28)
        snapshot(hwnd, "c3_memory_knot")
        resolve_c3_memory_vine(hwnd)
        clear_dialogue(timeout=8.0)
        snapshot(hwnd, "c3_memory")
        interact_at(hwnd, 60.0, -21.0, "c3 exit")
        wait_chapter(4, timeout=80.0)
        snapshot(hwnd, "c4_start")

        interact_at(hwnd, 2.6, -58.3, "c4 talk boatman")
        interact_at(hwnd, -5.1, -51.2, "c4 bell left")
        interact_at(hwnd, 5.1, -53.8, "c4 bell right")
        interact_at(hwnd, 0.0, -55.8, "c4 take kim")
        interact_at(hwnd, 2.6, -58.3, "c4 hear boatman")
        pyautogui.press("4")
        time.sleep(0.2)
        interact_at(hwnd, -5.7, -47.4, "c4 mark memorial")
        snapshot(hwnd, "c4_done")
        interact_at(hwnd, 2.6, -58.3, "c4 ready boat")
        interact_at(hwnd, 2.6, -58.3, "c4 cross river")
        wait_chapter(5, timeout=90.0)
        snapshot(hwnd, "c5_start")

        interact_at(hwnd, 5.75, -116.10, "c5 inspect foundation socket")
        interact_at(hwnd, -5.75, -116.10, "c5 take foundation stone")
        interact_at(hwnd, 5.75, -116.10, "c5 restore foundation")
        interact_at(hwnd, 5.75, -116.10, "c5 take tho")
        wait_until("Tho color unlocked", lambda s: s.get("current_color") == "tho", timeout=5.0)
        pyautogui.press("1")
        interact_at(hwnd, -3.25, -125.15, "c5 offer hoa")
        pyautogui.press("2")
        interact_at(hwnd, 3.25, -125.15, "c5 offer thuy")
        pyautogui.press("3")
        interact_at(hwnd, 5.25, -119.95, "c5 offer moc")
        pyautogui.press("4")
        interact_at(hwnd, 0.0, -116.65, "c5 offer kim")
        pyautogui.press("5")
        interact_at(hwnd, -5.25, -119.95, "c5 offer tho")
        clear_dialogue(timeout=120.0)
        interact_at(hwnd, 0.0, -123.45, "c5 cross bridge")
        wait_until("won state", lambda s: s.get("state") == WON, timeout=120.0)
        snapshot(hwnd, "won")
        final = read_state(2.0)
        print(f"GUI PLAYTHROUGH OK chapter={final.get('chapter')} state={final.get('state')} ending={final.get('ending')}")
    finally:
        release_movement()
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)


def main() -> None:
    parser = argparse.ArgumentParser(description="Desktop GUI driver for the Godot demo.")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=720)
    sub = parser.add_subparsers(dest="command", required=True)

    probe = sub.add_parser("probe", help="Launch, press Space, screenshot, and close.")
    probe.add_argument("--seconds", type=float, default=4.0)

    launch_parser = sub.add_parser("launch", help="Launch and focus the game window.")
    launch_parser.add_argument("--keep-open", action="store_true")

    sub.add_parser("playthrough", help="Drive C1-C5 with real keyboard input and telemetry.")

    args = parser.parse_args()
    if args.command == "probe":
        run_probe(args)
    elif args.command == "launch":
        run_launch(args)
    elif args.command == "playthrough":
        run_playthrough(args)


if __name__ == "__main__":
    main()
