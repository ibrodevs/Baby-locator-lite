from django.test import SimpleTestCase

from .services import has_premium_access, parent_can_add_child


class _Children:
    def __init__(self, count):
        self._count = count

    def count(self):
        return self._count


class _User:
    role = "parent"

    def __init__(self, *, is_premium=False, child_count=0, lite=False):
        self.is_premium = is_premium
        self.children = _Children(child_count)
        if lite:
            self._lite_full_access = True


class EditionAccessCompatibilityTests(SimpleTestCase):
    def test_paid_non_premium_keeps_original_restriction(self):
        user = _User(is_premium=False, child_count=1)
        self.assertFalse(has_premium_access(user))
        self.assertFalse(parent_can_add_child(user))

    def test_paid_premium_keeps_original_access(self):
        user = _User(is_premium=True, child_count=5)
        self.assertTrue(has_premium_access(user))
        self.assertTrue(parent_can_add_child(user))

    def test_lite_user_gets_full_access_without_db_premium(self):
        user = _User(is_premium=False, child_count=5, lite=True)
        self.assertTrue(has_premium_access(user))
        self.assertTrue(parent_can_add_child(user))
        self.assertFalse(user.is_premium)
