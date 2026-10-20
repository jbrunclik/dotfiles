"""Talk to a Kaleidoscope keyboard (Keyboardio Model 100) over its serial port.

Kaleidoscope's "Focus" protocol, the one Chrysalis uses: send `command` to
read a setting, `command value…` to write it; every answer ends with a line
holding a single ".". Used by keyboardio-backup and keyboardio-layers.
"""

import fcntl
import os
import plistlib
import select
import subprocess
import sys
import termios
import time

KEYBOARDIO_VENDOR_ID = 0x3496


def find_ports():
    """Serial ports of Keyboardio devices, found by USB vendor ID.

    Not the first /dev/cu.usbmodem*: any other USB serial gadget (a dev
    board, a UPS) gets one too, and would be sent a keymap.
    """
    out = subprocess.run(["ioreg", "-r", "-c", "IOUSBHostDevice", "-l", "-a"],
                         capture_output=True, check=True).stdout
    ports = []

    def callouts(node):
        if "IOCalloutDevice" in node:
            yield node["IOCalloutDevice"]
        for child in node.get("IORegistryEntryChildren", []):
            yield from callouts(child)

    def walk(node):
        if node.get("idVendor") == KEYBOARDIO_VENDOR_ID:
            ports.extend(callouts(node))
        else:
            for child in node.get("IORegistryEntryChildren", []):
                walk(child)

    for device in plistlib.loads(out) if out.strip() else []:
        walk(device)
    return sorted(ports)


class Keyboard:
    def __init__(self):
        ports = find_ports()
        if not ports:
            sys.exit("no Keyboardio keyboard found over USB — is the Model 100 plugged in?")
        if len(ports) > 1:
            sys.exit(f"more than one Keyboardio port ({', '.join(ports)}) — unplug all but one")
        self.port = ports[0]
        try:
            self.fd = os.open(self.port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        except OSError as e:
            sys.exit(f"cannot open {self.port}: {e.strerror} — quit Chrysalis, which holds the port")
        # Exclusive: Chrysalis opened mid-apply can't interleave its own
        # commands with ours (it gets EBUSY until we close)
        fcntl.ioctl(self.fd, termios.TIOCEXCL)
        attrs = termios.tcgetattr(self.fd)
        attrs[0] = attrs[1] = attrs[3] = 0  # raw: no input/output/line processing
        attrs[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
        attrs[4] = attrs[5] = termios.B9600  # ignored over USB, but must be set
        termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
        termios.tcflush(self.fd, termios.TCIOFLUSH)
        if "keymap.custom" not in self.commands():
            sys.exit(f"{self.port} doesn't look like a Kaleidoscope keyboard (no keymap.custom)")

    def request(self, command, value=None, timeout=10.0):
        """Send a command (a read, or a write when `value` is given); return the answer."""
        line = (command if value is None else f"{command} {value}") + "\n"
        data = line.encode()
        # Long writes (a keymap is ~2.5 kB) go in small chunks, as Chrysalis
        # does, so the keyboard's receive buffer can't overflow
        deadline = time.time() + timeout
        for i in range(0, len(data), 32):
            self._write_all(data[i:i + 32], command, deadline)
            if len(data) > 32:
                time.sleep(0.01)
        buf = b""
        while time.time() < deadline:
            ready, _, _ = select.select([self.fd], [], [], 0.2)
            if ready:
                buf += os.read(self.fd, 65536)
                text = buf.replace(b"\r", b"")
                if text == b".\n" or text.endswith(b"\n.\n"):
                    break
        else:
            sys.exit(f"no complete answer to '{command}'")
        lines = buf.decode(errors="replace").replace("\r", "").split("\n")[:-2]  # drop "." and ""
        # The keyboard pads values with a trailing space; Chrysalis trims them
        return "\n".join(line.rstrip() for line in lines)

    def _write_all(self, chunk, command, deadline):
        # The port is non-blocking, so os.write can take part of a chunk (or
        # none, with EAGAIN). Loop until all of it is out: dropped bytes would
        # shift every later key in the keymap, and the next command's text
        # would be read as the tail of this one.
        while chunk:
            _, ready, _ = select.select([], [self.fd], [], max(0, deadline - time.time()))
            if not ready:
                sys.exit(f"timed out sending '{command}' — the keyboard stopped reading")
            try:
                chunk = chunk[os.write(self.fd, chunk):]
            except BlockingIOError:
                pass

    def resync(self):
        """Get the keyboard listening for commands again after a failed request.

        A write cut short (a timeout, a line ending in a space) leaves the
        firmware still parsing numbers: it skips whitespace, newlines
        included, and fills each missing value with 0 after a 1 s wait — up to
        512 s for a keymap — and meanwhile reads our next command as more of
        the old one. Filler numbers finish that parse at once; the leftovers
        are answered as unknown commands and drained here. The interrupted
        setting holds garbage afterwards, so rewrite it.
        """
        termios.tcflush(self.fd, termios.TCIFLUSH)
        filler = ("0 " * 1024 + "\n").encode()
        deadline = time.time() + 10
        for i in range(0, len(filler), 32):
            self._write_all(filler[i:i + 32], "resync", deadline)
            time.sleep(0.01)
        quiet = time.time()
        while time.time() - quiet < 1.5:  # drain until the keyboard goes silent
            if select.select([self.fd], [], [], 0.2)[0]:
                os.read(self.fd, 65536)
                quiet = time.time()
        if "keymap.custom" not in self.commands():
            sys.exit("the keyboard doesn't answer 'help' cleanly after resync")

    def commands(self):
        return [c for c in self.request("help").split("\n") if c]

    def close(self):
        os.close(self.fd)
