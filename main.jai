#import "Basic";
#import "String";
#import "Windows";
#import "System";
#import "Deep_Copy";
#import "Hash_Table";
#import "Math";
#load "ui.jai";
#load "input.jai";
#load "util.jai";

#load "password_generator.jai";

window: *SDL_Window;

main :: ()
{
	SDL_Init(SDL_INIT_VIDEO);

	window = SDL_CreateWindow
	(
		"Password Generator", 
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED, 
		400, 400,
		SDL_WINDOW_OPENGL
	);

	if window == null 
	{
		print("Could not create window: %\n", to_string(SDL_GetError()));
		return;
	}

	print("%\n", to_string(ImGui.GetVersion()));
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
	gl_context := SDL_GL_CreateContext(window);
    if !gl_context 
	{
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }

	gl_load(*gl, SDL_GL_GetProcAddress);

    imgui_context := ImGui.CreateContext();

    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

	ImGui.StyleColorsClassic();

	io := ImGui.GetIO();

	running := true;
	is_quit: bool;
	clear_color := make_vector4(0, 0, 0, 1.00);
	main_tool_active: bool;

	settings: Generator_Settings;
	data: Generator_Data;
	state: Generator_State;
	copied: bool;

	while running
	{
		reset_temporary_storage();
		reset_controller_input(*global_input.keyboard);

		event: SDL_Event;
        while SDL_PollEvent(*event) 
		{
            ImGui_ImplSdl_ProcessEvent(*event);
            if event.type == SDL_QUIT   is_quit = true;
            if event.type == SDL_WINDOWEVENT && 
			   event.window.event == SDL_WINDOWEVENT_CLOSE && 
			   event.window.windowID == SDL_GetWindowID(window) 
			{
				running = false;
            }

			if event.type ==
			{
				case SDL_KEYDOWN; #through;
				case SDL_KEYUP;
				{
					is_down: bool = event.key.state == SDL_PRESSED;
					was_down: bool;
					
					if event.key.state == SDL_RELEASED
					{
						was_down = true;
					}
					else if event.key.repeat != 0
					{
						was_down = true;
					}
					
					if event.key.repeat == 0
					{
						key := event.key.keysym.scancode;
						
						button_state := table_find_pointer(*global_input.keyboard.keys, key);
						if button_state 
						{
							process_keypress(button_state, is_down, was_down);
						}
						else
						{
							new_state: Button_State;
							process_keypress(*new_state, is_down, was_down);
							table_add(*global_input.keyboard.keys, key, new_state);
						}
					}
				}
			}
        }

		ImGui_ImplSdl_NewFrame(window);
		ImGui.NewFrame();
		
		ImGui.Begin("Template", *main_tool_active, 
					IMGUI_WINDOW_FLAGS.NoTitleBar | 
					IMGUI_WINDOW_FLAGS.NoMove |
					IMGUI_WINDOW_FLAGS.NoResize |
					IMGUI_WINDOW_FLAGS.NoBackground);
		
		ImGui.SliderInt("Password Length", *settings.password_length, 8, 24);
		ImGui.Checkbox("Uppercase?", *settings.uppercase);
		ImGui.Checkbox("Lowercase?", *settings.lowercase);
		ImGui.Checkbox("Numbers?", *settings.numbers);
		ImGui.Checkbox("Symbols?", *settings.symbols);

		if ImGui.Button("Generate")
		{
			copied = false;
			if generate_password(settings, *data)
			{
				state = .Ok;
			}
		}

		if state == 
		{
			case .Ok;
			{
				ImGui.Text(to_string(data.password));
				ImGui.SameLine();
				if ImGui.Button("Copy")
				{
					if data.password then ImGui.SetClipboardText(data.password);
					copied = true;
				}
				ImGui.SameLine();
				if ImGui.Button("Clear")
				{
					if data.password
					{
						free(data.password);
						state = .Idle;
					}
					copied = false;
				}
			}
		}

		if copied then ImGui.Text("Copied to clipboard");

		ImGui.End();

		ImGui.Render();
        glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
        SDL_GL_SwapWindow(window);
	} 
}