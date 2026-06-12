from std.sys.defines import get_defined_string, get_defined_int

comptime board_size = get_defined_int["BoardSize", 19]()

comptime LoggingLevel = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime Trace = LoggingLevel == "TRACE"
comptime Debug = LoggingLevel == "DEBUG" or Trace
