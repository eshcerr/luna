package luna

import "core:fmt"
import "core:strings"
import win "core:sys/windows"

when ODIN_OS == .Windows {

	win_platform_state :: struct {
		window: win.HWND,
	}

	win_create_window :: proc(width, height: i32, title: string) -> bool {
		LUNA_WNDCLASS_NAME :: "winp_lunawnd"
		instance: win.HINSTANCE = win.HINSTANCE(win.GetModuleHandleW(nil))

		wc: win.WNDCLASSEXW
		wc.cbSize = size_of(wc)
		wc.style = win.CS_HREDRAW | win.CS_VREDRAW
		wc.lpfnWndProc = win_window_proc
		wc.hInstance = instance
		wc.lpszClassName = raw_data(win.utf8_to_utf16(LUNA_WNDCLASS_NAME))

		assert(bool(win.RegisterClassExW(&wc)), "LUNA_ASSERT > couldn't register window class")

		window = win.CreateWindowExW(
			win.WS_EX_LAYERED,
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

		assert(window != nil, "LUNA_ASSERT > couldn't create window")

		win.SetLayeredWindowAttributes(window, 0, 128, 0x0000_0002)

		win.ShowWindow(window, win.SW_SHOW)
		win.UpdateWindow(window)

		return true
	}

	win_update_window :: proc() {
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

	win_load_gl_function :: proc(funcName: string) -> (func: rawptr) {
		func = win.wglGetProcAddress(strings.clone_to_cstring(funcName))
		if func == nil {
			openGL_DLL := win.LoadLibraryW(raw_data(win.utf8_to_utf16("opengl32.dll")))
			func = win.GetProcAddress(openGL_DLL, strings.clone_to_cstring(funcName))
		}
		assert(func != nil, "LUNA_ASSERT > failed to load gl function")
		return
	}
}
