"""
utils.py - Simple utility functions for text processing.

This module provides basic text manipulation functions that serve as
the "application code" for testing the composite action. The functions
are intentionally simple so the focus stays on learning custom actions,
not debugging complex application logic.

These functions are tested by tests/unit/test_utils.py, which is
executed by the composite action (actions/setup-and-test).

Try breaking these functions to see how the pipeline catches bugs!
"""


def word_count(text):
    """
    Count the number of words in a string.

    Words are separated by whitespace. Empty strings return 0.

    Args:
        text: The input string to count words in.

    Returns:
        int: The number of words.

    Raises:
        TypeError: If text is not a string.

    Examples:
        >>> word_count("hello world")
        2
        >>> word_count("")
        0
    """
    if not isinstance(text, str):
        raise TypeError(f"Expected str, got {type(text).__name__}")
    if not text.strip():
        return 0
    return len(text.split())


def char_count(text):
    """
    Count the number of characters in a string (excluding whitespace).

    Args:
        text: The input string.

    Returns:
        int: Number of non-whitespace characters.

    Raises:
        TypeError: If text is not a string.

    Examples:
        >>> char_count("hello world")
        10
        >>> char_count("  spaces  ")
        6
    """
    if not isinstance(text, str):
        raise TypeError(f"Expected str, got {type(text).__name__}")
    return len(text.replace(" ", ""))


def reverse_string(text):
    """
    Reverse a string.

    Args:
        text: The input string.

    Returns:
        str: The reversed string.

    Raises:
        TypeError: If text is not a string.

    Examples:
        >>> reverse_string("hello")
        'olleh'
        >>> reverse_string("racecar")
        'racecar'
    """
    if not isinstance(text, str):
        raise TypeError(f"Expected str, got {type(text).__name__}")
    return text[::-1]


def is_palindrome(text):
    """
    Check if a string is a palindrome (reads the same forwards and backwards).

    Comparison is case-insensitive and ignores spaces.

    Args:
        text: The input string to check.

    Returns:
        bool: True if the string is a palindrome.

    Raises:
        TypeError: If text is not a string.

    Examples:
        >>> is_palindrome("racecar")
        True
        >>> is_palindrome("A man a plan a canal Panama")
        True
        >>> is_palindrome("hello")
        False
    """
    if not isinstance(text, str):
        raise TypeError(f"Expected str, got {type(text).__name__}")
    cleaned = text.lower().replace(" ", "")
    return cleaned == cleaned[::-1]


def capitalize_words(text):
    """
    Capitalize the first letter of each word in a string.

    Args:
        text: The input string.

    Returns:
        str: The string with each word capitalized.

    Raises:
        TypeError: If text is not a string.

    Examples:
        >>> capitalize_words("hello world")
        'Hello World'
        >>> capitalize_words("python is fun")
        'Python Is Fun'
    """
    if not isinstance(text, str):
        raise TypeError(f"Expected str, got {type(text).__name__}")
    return text.title()
