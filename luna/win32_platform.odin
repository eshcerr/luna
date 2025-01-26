package luna

import "core:c"
import "core:fmt"
import "core:strings"
import "core:sys/windows"
import gl "vendor:OpenGL"

when ODIN_OS == .Windows {
	win_platform_state_t :: struct {
		window: windows.HWND,
	}

	win_create_window :: proc(size: []i32, title: string) -> bool {
		using windows

		LUNA_WNDCLASS_NAME :: "winp_lunawnd"
		instance: HINSTANCE = HINSTANCE(GetModuleHandleW(nil))

		wc: WNDCLASSEXW
		wc.cbSize = size_of(wc)
		wc.style = CS_HREDRAW | CS_VREDRAW
		wc.lpfnWndProc = win_window_proc
		wc.hInstance = instance
		wc.lpszClassName = raw_data(utf8_to_utf16(LUNA_WNDCLASS_NAME))

		assert(bool(RegisterClassExW(&wc)), "LUNA_ASSERT > couldn't register window class")

		window := CreateWindowExW(
			WS_EX_LAYERED,
			raw_data(utf8_to_utf16(LUNA_WNDCLASS_NAME)),
			raw_data(utf8_to_utf16(title)),
			WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			size[0],
			size[1],
			nil,
			nil,
			instance,
			nil,
		)

		assert(window != nil, "LUNA_ASSERT > couldn't create window")

		//win.SetLayeredWindowAttributes(state.window, 0, 128, 0x0000_0002)

		{ 	// fake load opengl
			fake_dc: HDC = GetDC(window)
			assert(fake_dc != nil, "LUNA_ASSERT > failed to get HDC")

			pfd := PIXELFORMATDESCRIPTOR{}
			pfd.nSize = size_of(PIXELFORMATDESCRIPTOR)
			pfd.nVersion = 1
			pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
			pfd.iPixelType = PFD_TYPE_RGBA
			pfd.cColorBits = 32
			pfd.cAlphaBits = 8
			pfd.cDepthBits = 24

			pixel_format := ChoosePixelFormat(fake_dc, &pfd)
			assert(pixel_format != 0, "LUNA_ASSERT > failed to choose pixel format")
			assert(
				SetPixelFormat(fake_dc, pixel_format, &pfd) == TRUE,
				"LUNA_ASSERT > failed to set pixel format",
			)

			fake_rc := wglCreateContext(fake_dc)
			assert(fake_rc != nil, "LUNA_ASSERT > failed to create render context")
			assert(
				wglMakeCurrent(fake_dc, fake_rc) == TRUE,
				"LUNA_ASSERT > failed to make current",
			)

			wglMakeCurrent(fake_dc, HGLRC{})
			wglDeleteContext(fake_rc)
			ReleaseDC(window, fake_dc)
			DestroyWindow(window)
		}

		state := win_platform_state_t{}
		{ 	// real load gl
			border_rect := RECT{}
			AdjustWindowRectEx(&border_rect, WS_OVERLAPPEDWINDOW, FALSE, WS_EX_LAYERED)
			size[0] += (i32)(border_rect.right - border_rect.left)
			size[1] += (i32)(border_rect.bottom - border_rect.top)

			state.window = CreateWindowExW(
				WS_EX_LAYERED,
				raw_data(utf8_to_utf16(LUNA_WNDCLASS_NAME)),
				raw_data(utf8_to_utf16(title)),
				WS_OVERLAPPEDWINDOW,
				CW_USEDEFAULT,
				CW_USEDEFAULT,
				size[0],
				size[1],
				nil,
				nil,
				instance,
				nil,
			)
			log_info("1")
			assert(state.window != nil, "LUNA_ASSERT > couldn't create window")

			dc: HDC = GetDC(state.window)
			log_info("2")
			assert(dc != nil, "LUNA_ASSERT > failed to get HDC")

			pixel_attribs: []c.int = {
				WGL_DRAW_TO_WINDOW_ARB,
				1,
				WGL_SUPPORT_OPENGL_ARB,
				1,
				WGL_DOUBLE_BUFFER_ARB,
				1,
				WGL_SWAP_METHOD_ARB,
				WGL_SWAP_COPY_ARB,
				WGL_PIXEL_TYPE_ARB,
				WGL_TYPE_RGBA_ARB,
				WGL_ACCELERATION_ARB,
				WGL_FULL_ACCELERATION_ARB,
				WGL_COLOR_BITS_ARB,
				32,
				WGL_ALPHA_BITS_ARB,
				8,
				WGL_DEPTH_BITS_ARB,
				24,
				0,
			}

			num_pixel_format: DWORD
			pixel_format: c.int

			log_info("3")
			assert(
				wglChoosePixelFormatARB(
					dc,
					&pixel_attribs[0],
					cast([^]f32)(nil),
					cast(u32)(1),
					&pixel_format,
					&num_pixel_format,
				) ==
				TRUE,
				"LUNA_ASSERT > failed to wglChoosePixelFormatARB",
			)

			pfd := PIXELFORMATDESCRIPTOR{}
			DescribePixelFormat(dc, pixel_format, size_of(PIXELFORMATDESCRIPTOR), &pfd)
			log_info("4")
			assert(
				SetPixelFormat(dc, pixel_format, &pfd) == TRUE,
				"LUNA_ASSERT > failed to set pixel format",
			)

			context_attribs: []c.int = {
				WGL_CONTEXT_MAJOR_VERSION_ARB,
				4,
				WGL_CONTEXT_MINOR_VERSION_ARB,
				3,
				WGL_CONTEXT_PROFILE_MASK_ARB,
				WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
				WGL_CONTEXT_FLAGS_ARB,
				WGL_CONTEXT_DEBUG_BIT_ARB,
				0,
			}

			rc := wglCreateContextAttribsARB(dc, nil, &context_attribs[0])
			log_info("5")
			assert(rc != nil, "LUNA_ASSERT > failed to create render context")
			log_info("6")
			assert(
				wglMakeCurrent(dc, rc) == TRUE,
				"LUNA_ASSERT > failed to make current",
			)
		}

		ShowWindow(state.window, SW_SHOW)
		UpdateWindow(state.window)

		platform_state = state
		return true
	}

	win_update_window :: proc() {
		using windows

		msg: MSG
		for {
			if PeekMessageW(&msg, platform_state.(win_platform_state_t).window, 0, 0, PM_REMOVE) ==
			   FALSE {
				break
			}
			TranslateMessage(&msg)
			DispatchMessageW(&msg)
		}
	}

	win_window_proc :: proc "std" (
		hwnd: windows.HWND,
		uMsg: u32,
		wParam: windows.WPARAM,
		lParam: windows.LPARAM,
	) -> windows.LRESULT {
		using windows

		switch uMsg {
		case WM_DESTROY:
			{
				PostQuitMessage(0)
				running = false
				return 0
			}
		}
		return DefWindowProcW(hwnd, uMsg, wParam, lParam)
	}
}
