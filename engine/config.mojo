from std.sys.defines import get_defined_int, get_defined_string

comptime board_size = get_defined_int["BoardSize", 19]()
comptime game_name = get_defined_string["Game", "Connect6"]()
comptime win_stones = 6 if game_name == "Connect6" else 5

comptime LoggingLevel = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime Trace = LoggingLevel == "TRACE"
comptime Debug = LoggingLevel == "DEBUG" or Trace
