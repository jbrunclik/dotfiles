"""Talk to a Kaleidoscope keyboard (Keyboardio Model 100) over its serial port.

Kaleidoscope's "Focus" protocol, the one Chrysalis uses: send `command` to
read a setting, `command value…` to write it; every answer ends with a line
holding a single ".". Used by keyboardio-backup and keyboardio-layers.
"""

import glob
import os
import select
import sys
import termios
import time


class Keyboard:
    def __init__(self):
        ports = sorted(glob.glob("/dev/cu.usbmodem*"))
        if not ports:
            sys.exit("no keyboard found (no /dev/cu.usbmodem* port) — is the Model 100 plugged in?")
        self.port = ports[0]
        try:
            self.fd = os.open(self.port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        except OSError as e:
            sys.exit(f"cannot open {self.port}: {e.strerror} — quit Chrysalis, which holds the port")
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
        for i in range(0, len(data), 32):
            os.write(self.fd, data[i:i + 32])
            if len(data) > 32:
                time.sleep(0.01)
        buf, deadline = b"", time.time() + timeout
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

    def commands(self):
        return [c for c in self.request("help").split("\n") if c]

    def close(self):
        os.close(self.fd)
