from __future__ import annotations

import contextlib
import importlib.machinery
import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
LOADER = importlib.machinery.SourceFileLoader("keychron_profiles", str(ROOT / "keychron-profiles"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
assert SPEC is not None
kp = importlib.util.module_from_spec(SPEC)
sys.modules[LOADER.name] = kp
LOADER.exec_module(kp)


def get_response(index: int = 0, count: int = 3, size: int = 512) -> bytes:
    data = bytearray(32)
    data[0:2] = bytes((0xA9, 0x10))
    data[2] = index
    data[3] = count
    data[4] = size & 0xFF
    data[5] = size >> 8
    data[6] = 4
    data[7] = 2
    return bytes(data)


def select_response(status: int = 0) -> bytes:
    data = bytearray(32)
    data[0:2] = bytes((0xA9, 0x11))
    data[2] = status
    return bytes(data)


class FixtureTree:
    def __init__(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.sysfs = self.root / "sys"
        self.dev = self.root / "dev"
        self.sysfs.mkdir()
        self.dev.mkdir()

    def close(self) -> None:
        self.temp.cleanup()

    def add(
        self,
        number: int,
        *,
        serial: str = "SERIAL1",
        pid: str = "0EA1",
        descriptor: bytes = kp.EXPECTED_DESCRIPTOR,
        product: str = "Keychron Keychron K10 HE",
    ) -> None:
        entry = self.sysfs / f"hidraw{number}" / "device"
        entry.mkdir(parents=True)
        (entry / "uevent").write_text(
            "\n".join(
                (
                    "DRIVER=hid-generic",
                    f"HID_ID=0003:00003434:0000{pid}",
                    f"HID_NAME={product}",
                    f"HID_PHYS=usb-test/input{number}",
                    f"HID_UNIQ={serial}",
                )
            )
            + "\n",
            encoding="utf-8",
        )
        (entry / "report_descriptor").write_bytes(descriptor)
        (self.dev / f"hidraw{number}").touch()


class FakeTransport:
    def __init__(self, responses: list[bytes | Exception]):
        self.responses = list(responses)
        self.calls: list[tuple[bytes, int]] = []

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return None

    def exchange(self, payload: bytes, command: int, timeout: float = kp.COMMAND_TIMEOUT) -> bytes:
        self.calls.append((payload, command))
        response = self.responses.pop(0)
        if isinstance(response, Exception):
            raise response
        return response


class FramingTests(unittest.TestCase):
    def test_get_command_is_exactly_one_allowlisted_32_byte_payload(self) -> None:
        command = kp.build_command(kp.GET_PROFILES_INFO)
        self.assertEqual(len(command), 32)
        self.assertEqual(command[:3], b"\xa9\x10\x00")
        self.assertEqual(command[3:], bytes(29))

    def test_select_allows_only_default_and_gamepad_indices(self) -> None:
        self.assertEqual(kp.build_command(kp.SELECT_PROFILE, 0)[:3], b"\xa9\x11\x00")
        self.assertEqual(kp.build_command(kp.SELECT_PROFILE, 2)[:3], b"\xa9\x11\x02")
        with self.assertRaises(ValueError):
            kp.build_command(kp.SELECT_PROFILE, 1)
        with self.assertRaises(ValueError):
            kp.build_command(0x20)

    def test_get_response_is_strictly_validated(self) -> None:
        parsed = kp.parse_get_response(get_response(2))
        self.assertEqual(parsed["activeIndex"], 2)
        self.assertEqual(parsed["profileCount"], 3)
        for invalid in (
            get_response()[:-1],
            bytes(32),
            get_response(0, count=4),
            get_response(3),
            get_response(0, size=0),
        ):
            with self.subTest(invalid=invalid):
                with self.assertRaises(kp.HelperError):
                    kp.parse_get_response(invalid)

    def test_select_response_requires_matching_success(self) -> None:
        kp.parse_select_response(select_response(0))
        with self.assertRaises(kp.HelperError):
            kp.parse_select_response(select_response(1))
        wrong = bytearray(select_response())
        wrong[1] = 0x10
        with self.assertRaises(kp.HelperError):
            kp.parse_select_response(bytes(wrong))

    def test_timeout_is_not_converted_to_success(self) -> None:
        transport = FakeTransport([kp.ProtocolTimeout("test timeout")])
        with self.assertRaises(kp.ProtocolTimeout):
            kp.read_info(transport)


class DiscoveryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = FixtureTree()

    def tearDown(self) -> None:
        self.fixture.close()

    def test_missing_device_fails_closed(self) -> None:
        with self.assertRaisesRegex(kp.HelperError, "No supported wired K10 HE") as caught:
            kp.discover_device(sysfs_root=self.fixture.sysfs, dev_root=self.fixture.dev)
        self.assertEqual(caught.exception.state, "disconnected")

    def test_descriptor_mismatch_is_unsupported(self) -> None:
        self.fixture.add(1, descriptor=b"not-the-verified-descriptor")
        with self.assertRaises(kp.HelperError) as caught:
            kp.discover_device(sysfs_root=self.fixture.sysfs, dev_root=self.fixture.dev)
        self.assertEqual(caught.exception.state, "unsupported")

    def test_exact_serial_disambiguates_two_keyboards(self) -> None:
        self.fixture.add(1, serial="FIRST")
        self.fixture.add(2, serial="SECOND")
        with self.assertRaises(kp.HelperError) as caught:
            kp.discover_device(sysfs_root=self.fixture.sysfs, dev_root=self.fixture.dev)
        self.assertEqual(caught.exception.state, "ambiguous")
        chosen = kp.discover_device(
            "SECOND", sysfs_root=self.fixture.sysfs, dev_root=self.fixture.dev
        )
        self.assertEqual(chosen.serial, "SECOND")
        self.assertEqual(chosen.path, self.fixture.dev / "hidraw2")

    def test_product_mismatch_on_supported_id_is_unsupported(self) -> None:
        self.fixture.add(1, product="Keychron Q1 HE")
        with self.assertRaises(kp.HelperError) as caught:
            kp.discover_device(sysfs_root=self.fixture.sysfs, dev_root=self.fixture.dev)
        self.assertEqual(caught.exception.state, "unsupported")

    def test_unapproved_q1_pid_is_never_a_candidate(self) -> None:
        self.fixture.add(2, pid="0B11")
        with self.assertRaises(kp.HelperError) as caught:
            kp.discover_device(sysfs_root=self.fixture.sysfs, dev_root=self.fixture.dev)
        self.assertEqual(caught.exception.state, "disconnected")


class SelectionTests(unittest.TestCase):
    candidate = kp.Candidate(
        path=Path("/dev/hidraw-test"),
        serial="SERIAL1",
        product="Keychron Keychron K10 HE",
        vid="3434",
        pid="0EA1",
        physical_path="usb-test/input1",
    )

    def run_with_transport(self, transport: FakeTransport, profile: str):
        with (
            mock.patch.object(kp, "OperationLock", return_value=contextlib.nullcontext()),
            mock.patch.object(kp, "discover_device", return_value=self.candidate),
            mock.patch.object(kp, "HidTransport", return_value=transport),
        ):
            return kp.run_select("SERIAL1", profile)

    def test_redundant_select_is_skipped(self) -> None:
        transport = FakeTransport([get_response(0)])
        result = self.run_with_transport(transport, "default")
        self.assertFalse(result["changed"])
        self.assertEqual([call[1] for call in transport.calls], [kp.GET_PROFILES_INFO])

    def test_select_is_verified_with_a_fresh_get(self) -> None:
        transport = FakeTransport([get_response(0), select_response(), get_response(2)])
        result = self.run_with_transport(transport, "gamepad")
        self.assertTrue(result["changed"])
        self.assertEqual(result["activeIndex"], 2)
        self.assertEqual(
            [call[1] for call in transport.calls],
            [kp.GET_PROFILES_INFO, kp.SELECT_PROFILE, kp.GET_PROFILES_INFO],
        )
        self.assertEqual(transport.calls[1][0][2], 2)

    def test_lost_select_response_uses_get_without_retry(self) -> None:
        transport = FakeTransport(
            [get_response(0), kp.ProtocolTimeout("lost response"), get_response(2)]
        )
        result = self.run_with_transport(transport, "gamepad")
        self.assertTrue(result["responseRecovered"])
        self.assertEqual(
            [call[1] for call in transport.calls],
            [kp.GET_PROFILES_INFO, kp.SELECT_PROFILE, kp.GET_PROFILES_INFO],
        )

    def test_wrong_post_select_state_fails(self) -> None:
        transport = FakeTransport([get_response(0), select_response(), get_response(0)])
        with self.assertRaises(kp.HelperError) as caught:
            self.run_with_transport(transport, "gamepad")
        self.assertEqual(caught.exception.state, "verification_failed")

    def test_permission_error_is_reported_without_elevation(self) -> None:
        with mock.patch.object(os, "open", side_effect=PermissionError()):
            with self.assertRaises(kp.HelperError) as caught:
                with kp.HidTransport(self.candidate):
                    pass
        self.assertEqual(caught.exception.state, "permission_denied")


if __name__ == "__main__":
    unittest.main()
