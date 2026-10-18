import importlib.util
import unittest
from datetime import datetime, timezone
from pathlib import Path


SCRIPT = Path(__file__).with_name("seed_presentation.py")
SPEC = importlib.util.spec_from_file_location("seed_presentation", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
seed_presentation = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(seed_presentation)


class FirestoreEncodingTest(unittest.TestCase):
    def test_encodes_supported_firestore_values(self):
        encoded = seed_presentation.document(
            {
                "name": "Maria",
                "active": True,
                "repetitions": 3,
                "confidence": 0.9,
                "optional": None,
                "createdAt": datetime(2026, 10, 18, tzinfo=timezone.utc),
                "items": ["a", 2],
                "details": {"side": "right"},
            }
        )["fields"]

        self.assertEqual(encoded["name"], {"stringValue": "Maria"})
        self.assertEqual(encoded["active"], {"booleanValue": True})
        self.assertEqual(encoded["repetitions"], {"integerValue": "3"})
        self.assertEqual(encoded["confidence"], {"doubleValue": 0.9})
        self.assertEqual(encoded["optional"], {"nullValue": None})
        self.assertEqual(encoded["createdAt"], {"timestampValue": "2026-10-18T00:00:00.000Z"})
        self.assertEqual(
            encoded["items"]["arrayValue"]["values"][1], {"integerValue": "2"}
        )
        self.assertEqual(
            encoded["details"]["mapValue"]["fields"]["side"],
            {"stringValue": "right"},
        )


if __name__ == "__main__":
    unittest.main()
