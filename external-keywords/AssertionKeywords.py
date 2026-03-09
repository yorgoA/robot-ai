"""
AssertionKeywords.py
--------------------
Natural-language assertion keywords that replace Robot Framework built-ins
(Should Be Equal, Should Be True, etc.) with BDD-friendly phrasing.

Usage in .resource / .robot files:
    Library    ../../external-keywords/AssertionKeywords.py
"""


class AssertionKeywords:
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_DOC_FORMAT = "reST"

    def the_number_is_equal_to(self, actual, expected):
        """Asserts ``actual == expected`` as integers."""
        assert int(actual) == int(expected), f"Expected {expected} but got {actual}"

    def the_count_is(self, actual, expected):
        """Asserts a count equals the expected integer value."""
        assert int(actual) == int(expected), f"Expected count {expected} but got {actual}"

    def the_count_is_greater_than(self, actual, threshold):
        """Asserts a count is strictly greater than threshold."""
        assert int(actual) > int(threshold), f"Expected count > {threshold} but got {actual}"

    def the_text_is(self, actual, expected):
        """Asserts two text values are equal (whitespace-trimmed)."""
        assert str(actual).strip() == str(expected).strip(), \
            f"Expected '{expected}' but got '{actual}'"

    def the_text_is_not_empty(self, text):
        """Asserts a string contains at least one non-whitespace character."""
        assert str(text).strip() != "", "Expected text to not be empty"

    def the_value_is_greater_than(self, actual, threshold):
        """Asserts actual > threshold as floats."""
        assert float(actual) > float(threshold), \
            f"Expected {actual} to be greater than {threshold}"

    def the_list_is_not_empty(self, collection):
        """Asserts a list or dict contains at least one item."""
        assert len(collection) > 0, "Expected collection to not be empty"

    def the_response_status_is(self, response, expected_code):
        """Asserts the HTTP response status code equals expected_code."""
        actual = response.status_code
        assert actual == int(expected_code), \
            f"Expected HTTP {expected_code} but got {actual}"

    def the_response_contains_key(self, response, key):
        """Asserts that the JSON response body contains the given key."""
        body = response.json()
        assert key in body, \
            f"Expected key '{key}' in response, got keys: {list(body.keys())}"

    def the_response_body_is_a_list(self, response):
        """Asserts that the JSON response body is a list."""
        body = response.json()
        assert isinstance(body, list), \
            f"Expected list response, got {type(body).__name__}"

    def each_item_has_field(self, items, field):
        """Asserts that every item in a list contains the given field."""
        for i, item in enumerate(items):
            assert field in item, f"Item {i} is missing field '{field}': {item}"
