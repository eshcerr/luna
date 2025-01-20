package luna

import "core:fmt"
import win "core:sys/windows"

window_create :: proc {
	win_window_create,
}
window_update :: proc {
	win_window_update,
}

window: win.HWND

win_window_create :: proc(width, height: i32, title: string) -> bool {
	LUNA_WNDCLASS_NAME :: "lunawnd"
	instance: win.HINSTANCE = win.HINSTANCE(win.GetModuleHandleW(nil))

	wc: win.WNDCLASSEXW
	wc.cbSize = size_of(wc)
	wc.style = win.CS_HREDRAW | win.CS_VREDRAW
	wc.lpfnWndProc = win_window_proc
	wc.hInstance = instance
	wc.lpszClassName = raw_data(win.utf8_to_utf16(LUNA_WNDCLASS_NAME))

	if bool(win.RegisterClassExW(&wc)) == false {
		fmt.println("couldn't register class")
		return false
	}

	window = win.CreateWindowExW(
		win.WS_EX_LAYERED | win.WS_EX_TOPMOST,
		raw_data(win.utf8_to_utf16(LUNA_WNDCLASS_NAME)),
		raw_data(win.utf8_to_utf16(title)),
		win.WS_OVERLAPPEDWINDOW,
		win.CW_USEDEFAULT,
		win.CW_USEDEFAULT,
		width,
		height,
		nil,
		nil,
		instance,
		nil,
	)

	if window == nil {
		fmt.println("couldn't create window")
		return false
	}

	win.SetLayeredWindowAttributes(window, 0, 128, 0x0000_0002)

	win.ShowWindow(window, win.SW_SHOW)
	win.UpdateWindow(window)

	fmt.println("created window")

	return true
}

win_window_update :: proc() {
	msg: win.MSG
	for {
		if win.PeekMessageW(&msg, window, 0, 0, win.PM_REMOVE) == win.FALSE {
			break
		}
		win.TranslateMessage(&msg)
		win.DispatchMessageW(&msg)
	}
}

win_window_proc :: proc "std" (
	hwnd: win.HWND,
	uMsg: u32,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	switch uMsg {
	case win.WM_DESTROY:
		{
			win.PostQuitMessage(0)
			running = false
			return 0
		}
	}
	return win.DefWindowProcW(hwnd, uMsg, wParam, lParam)
}
