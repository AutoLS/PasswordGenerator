letters :: "qwertyuiopasdfghjklzxcvbnm";
symbols :: "!\"#$&'()*+,-./:;<=>?@[\\]^_`{|}~";
numbers :: "0123456789";

Generator_Settings :: struct 
{
    password_length: s32 = 8;
    uppercase: bool;
    lowercase: bool;
    symbols: bool;
    numbers: bool;
}

Generator_Data :: struct
{
    password: *u8;
}

Generator_State :: enum u32
{
    Idle;
    Ok;
    Error;
}

generate_password :: (settings: Generator_Settings, data: *Generator_Data) -> bool
{
    if data.password 
    {
        free(data.password);
    }

    uppercase := to_upper_copy(letters);

    password: *u8 = alloc(settings.password_length+1);
    memset(password, 0, settings.password_length+1);

    options: [..] string;
    options.allocator = temp;
    if settings.uppercase then array_add(*options, "uppercase");
    if settings.lowercase then array_add(*options, "lowercase");
    if settings.symbols then array_add(*options, "symbols");
    if settings.numbers then array_add(*options, "numbers");

    for index: 0 .. settings.password_length-1 
    {
        if options.count > 0
        {
            o: int = random_int(0, options.count-1);
            if options[o] == 
            {
                case "uppercase"; 
                {
                    password[index] = uppercase[random_int(0, uppercase.count-1)];
                }
                case "lowercase";
                {
                    password[index] = letters[random_int(0, letters.count-1)];
                }
                case "symbols";
                {
                    password[index] = symbols[random_int(0, symbols.count-1)];
                }
                case "numbers";
                {
                    password[index] = numbers[random_int(0, numbers.count-1)];
                }
            }
        }
        else
        {
            password[index] = letters[random_int(0, letters.count-1)];
        }
    }

    data.password = password;

    return true;
}