"""
test_utils.py - Unit tests for app/utils.py

These tests verify that all utility functions work correctly.
The composite action (actions/setup-and-test) runs these tests
automatically as part of the GitHub Actions workflow.

Each test class groups related tests for a single function.
Try breaking a function in utils.py and see which tests fail!
"""

import pytest
from app.utils import word_count, char_count, reverse_string, is_palindrome, capitalize_words


# ==========================================================================
# TESTS FOR word_count()
# ==========================================================================

class TestWordCount:
    """Tests for the word_count function."""

    def test_simple_sentence(self):
        """Two words should return 2."""
        assert word_count("hello world") == 2

    def test_single_word(self):
        """One word should return 1."""
        assert word_count("hello") == 1

    def test_empty_string(self):
        """Empty string should return 0."""
        assert word_count("") == 0

    def test_whitespace_only(self):
        """Whitespace-only string should return 0."""
        assert word_count("   ") == 0

    def test_multiple_spaces(self):
        """Multiple spaces between words should still count correctly."""
        assert word_count("hello    world") == 2

    def test_invalid_input(self):
        """Non-string input should raise TypeError."""
        with pytest.raises(TypeError):
            word_count(123)


# ==========================================================================
# TESTS FOR char_count()
# ==========================================================================

class TestCharCount:
    """Tests for the char_count function."""

    def test_simple_string(self):
        """'hello world' has 10 non-space characters."""
        assert char_count("hello world") == 10

    def test_no_spaces(self):
        """String without spaces should count all characters."""
        assert char_count("hello") == 5

    def test_empty_string(self):
        """Empty string should return 0."""
        assert char_count("") == 0

    def test_only_spaces(self):
        """Spaces-only string should return 0."""
        assert char_count("   ") == 0

    def test_invalid_input(self):
        """Non-string input should raise TypeError."""
        with pytest.raises(TypeError):
            char_count(None)


# ==========================================================================
# TESTS FOR reverse_string()
# ==========================================================================

class TestReverseString:
    """Tests for the reverse_string function."""

    def test_simple_reverse(self):
        """'hello' reversed is 'olleh'."""
        assert reverse_string("hello") == "olleh"

    def test_palindrome(self):
        """A palindrome reversed should equal itself."""
        assert reverse_string("racecar") == "racecar"

    def test_empty_string(self):
        """Empty string reversed is still empty."""
        assert reverse_string("") == ""

    def test_single_char(self):
        """Single character reversed is itself."""
        assert reverse_string("a") == "a"

    def test_invalid_input(self):
        """Non-string input should raise TypeError."""
        with pytest.raises(TypeError):
            reverse_string(42)


# ==========================================================================
# TESTS FOR is_palindrome()
# ==========================================================================

class TestIsPalindrome:
    """Tests for the is_palindrome function."""

    def test_simple_palindrome(self):
        """'racecar' is a palindrome."""
        assert is_palindrome("racecar") is True

    def test_not_palindrome(self):
        """'hello' is not a palindrome."""
        assert is_palindrome("hello") is False

    def test_case_insensitive(self):
        """Palindrome check should be case-insensitive."""
        assert is_palindrome("Racecar") is True

    def test_with_spaces(self):
        """Palindrome check should ignore spaces."""
        assert is_palindrome("a man a plan a canal panama") is True

    def test_empty_string(self):
        """Empty string is a palindrome."""
        assert is_palindrome("") is True

    def test_single_char(self):
        """Single character is a palindrome."""
        assert is_palindrome("x") is True

    def test_invalid_input(self):
        """Non-string input should raise TypeError."""
        with pytest.raises(TypeError):
            is_palindrome(123)


# ==========================================================================
# TESTS FOR capitalize_words()
# ==========================================================================

class TestCapitalizeWords:
    """Tests for the capitalize_words function."""

    def test_simple_sentence(self):
        """Each word should be capitalized."""
        assert capitalize_words("hello world") == "Hello World"

    def test_already_capitalized(self):
        """Already capitalized text should remain the same."""
        assert capitalize_words("Hello World") == "Hello World"

    def test_all_lowercase(self):
        """All lowercase words should be capitalized."""
        assert capitalize_words("python is fun") == "Python Is Fun"

    def test_empty_string(self):
        """Empty string should return empty string."""
        assert capitalize_words("") == ""

    def test_single_word(self):
        """Single word should be capitalized."""
        assert capitalize_words("python") == "Python"

    def test_invalid_input(self):
        """Non-string input should raise TypeError."""
        with pytest.raises(TypeError):
            capitalize_words(999)
