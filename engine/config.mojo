from std.sys.defines import get_defined_string

comptime AssertMode = get_defined_string["ASSERT", "none"]()
comptime Assert = AssertMode == "all"
comptime LoggingLevel = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime Trace = LoggingLevel == "TRACE"
comptime Debug = LoggingLevel == "DEBUG" or Trace
