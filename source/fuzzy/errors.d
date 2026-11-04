module fuzzy.errors;

/** Base class for fuzzy-d contract violations. */
class FuzzyException : Exception
{
    this(string message, string file = __FILE__, size_t line = __LINE__)
    {
        super(message, file, line);
    }
}

/** Invalid model, expression, parameter or rule definition. */
class ValidationException : FuzzyException
{
    this(string message, string file = __FILE__, size_t line = __LINE__)
    {
        super(message, file, line);
    }
}

/** Evaluation requested a value for which no input was supplied. */
class MissingInputException : FuzzyException
{
    this(string message, string file = __FILE__, size_t line = __LINE__)
    {
        super(message, file, line);
    }
}
