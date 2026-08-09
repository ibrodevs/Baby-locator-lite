import hashlib
import hmac

from django.conf import settings
from rest_framework.authentication import TokenAuthentication
from rest_framework.exceptions import AuthenticationFailed


LITE_TOKEN_PREFIX = "lite"


def _lite_signature(token_key: str) -> str:
    signing_key = settings.LITE_TOKEN_SIGNING_KEY.encode("utf-8")
    payload = f"{LITE_TOKEN_PREFIX}:{token_key}".encode("utf-8")
    return hmac.new(signing_key, payload, hashlib.sha256).hexdigest()


def build_lite_token(token_key: str) -> str:
    """Wrap a normal DRF token in a backend-signed Lite edition token."""
    return f"{LITE_TOKEN_PREFIX}.{token_key}.{_lite_signature(token_key)}"


class EditionTokenAuthentication(TokenAuthentication):
    """Authenticate both legacy paid tokens and signed Lite edition tokens.

    Existing paid clients keep sending `Token <key>` and follow the original
    subscription rules. Baby Locator Lite exchanges that key once for
    `Token lite.<key>.<signature>`; after signature verification we only mark
    the in-memory request user as having Lite access. No database premium
    fields are changed.
    """

    def authenticate_credentials(self, key):
        raw_key = key
        is_lite = False

        if key.startswith(f"{LITE_TOKEN_PREFIX}."):
            parts = key.split(".", 2)
            if len(parts) != 3:
                raise AuthenticationFailed("Invalid Lite token.")

            _, token_key, signature = parts
            expected = _lite_signature(token_key)
            if not hmac.compare_digest(signature, expected):
                raise AuthenticationFailed("Invalid Lite token signature.")

            raw_key = token_key
            is_lite = True

        user, token = super().authenticate_credentials(raw_key)
        if is_lite:
            setattr(user, "_lite_full_access", True)
        return user, token
