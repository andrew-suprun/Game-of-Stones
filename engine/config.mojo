from std.sys.defines import get_defined_string

comptime LoggingLevel = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime Trace = LoggingLevel == "TRACE"
comptime Debug = LoggingLevel == "DEBUG" or Trace
